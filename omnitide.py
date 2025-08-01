# omnitide.py
import typer
import subprocess
import sys
from typing import Optional
from rich.console import Console
from rich.panel import Panel
from rich import box

app = typer.Typer(help="Omnitide AI Suite - Dynamic MLOps & LLM Platform CLI")
console = Console()

def run_command(command: str):
    """Execute a shell command with proper error handling."""
    with console.status(f"[bold green]Running: {command}[/bold green]"):
        try:
            process = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
            if process.stdout:
                for line in iter(process.stdout.readline, ''):
                    console.print(f"  [grey46]{line.strip()}[/grey46]")
            process.wait()
            if process.returncode != 0:
                console.print(f"[bold red]Command failed with return code {process.returncode}[/bold red]")
                sys.exit(process.returncode)
        except (OSError, subprocess.SubprocessError) as e:
            console.print(f"[bold red]Command execution error: {e}[/bold red]")
            sys.exit(1)
        except Exception as e:
            console.print(f"[bold red]An error occurred: {e}[/bold red]")
            sys.exit(1)
    console.print(f"[bold green]Command completed successfully.[/bold green]")

@app.command(help="Runs the FastAPI application in a development server.")
def run():
    run_command("poetry run uvicorn main:app --reload")

@app.command(help="Runs the unit test suite and generates a coverage report.")
def test(coverage: Optional[bool] = typer.Option(True, "--no-coverage", help="Run tests without a coverage report.")):
    if coverage:
        run_command("poetry run pytest --cov=src")
    else:
        run_command("poetry run pytest")

@app.command(help="Runs the code linter and formatter.")
def lint():
    run_command("poetry run ruff check . && poetry run ruff format .")

@app.command(help="Runs the full CI/CD pipeline locally.")
def ci():
    """Run the full CI/CD pipeline locally."""
    console.print("[bold cyan]Executing full CI pipeline locally...[/bold cyan]")
    lint()
    test()
    console.print("[bold cyan]CI pipeline steps completed.[/bold cyan]")

@app.command(help="Cleans up temporary artifacts and resets the environment.")
def clean():
    console.print("[bold yellow]Cleaning up artifacts and resetting environment...[/bold yellow]")
    run_command("rm -rf .venv/ __pycache__/ reports/ coverage.xml models/ data/processed/")
    run_command("dvc destroy")
    console.print("[bold yellow]Cleanup and reset complete.[/bold yellow]")

@app.command(help="Orchestrate intelligent agent tasks and self-healing operations.")
def agent(
    task: str = typer.Argument(..., help="Task to execute: heal, detect, adapt, monitor"),
    params: Optional[str] = typer.Option(None, "--params", "-p", help="JSON parameters for the task")
):
    """Orchestrate agent tasks with intelligent configuration."""
    try:
        from src.intelligent_config import IntelligentConfig
        intelligent_config = IntelligentConfig()
        
        # Parse parameters if provided
        task_params = {}
        if params:
            import json
            task_params = json.loads(params)
        
        console.print(f"[bold cyan]🤖 Executing agent task: {task}[/bold cyan]")
        
        result = intelligent_config.orchestrate_agent_task(task, task_params)
        
        if result.get("success"):
            console.print(f"[bold green]✅ Task '{task}' completed successfully![/bold green]")
            # Pretty print the result if it's a dict or list
            if isinstance(result.get("result"), (dict, list)):
                from rich.pretty import pprint
                pprint(result.get("result"))
            else:
                console.print(f"Result: {result.get('result')}")
        else:
            console.print(f"[bold red]❌ Task '{task}' failed: {result.get('error', 'Unknown error')}[/bold red]")
                
    except ImportError:
        console.print("[bold red]❌ Intelligent configuration not available[/bold red]")
    except Exception as e:
        console.print(f"[bold red]❌ Agent task failed: {e}[/bold red]")

@app.command(help="Interactive mode for dynamic project management.")
def interactive():
    """Interactive mode with dynamic menu based on available capabilities."""
    try:
        from src.intelligent_config import IntelligentConfig
        intelligent_config = IntelligentConfig()
        
        while True:
            console.clear()
            console.print(Panel(
                "[bold cyan]🚀 Omnitide AI Suite - Interactive Mode[/bold cyan]",
                subtitle="Dynamic MLOps & LLM Platform",
                box=box.DOUBLE
            ))
            
            # Detect current capabilities
            env_info = intelligent_config.detect_environment()
            
            console.print("[bold]Available Actions:[/bold]")
            console.print("1. 🔧 Heal Project (Auto-fix issues)")
            console.print("2. 🚀 Start API Server")
            console.print("3. 🧪 Run Tests")
            console.print("4. 🔍 Environment Detection")
            console.print("5. ⚙️ Adapt Configuration")
            console.print("6. 📊 System Monitor")
            
            if env_info.get("has_ollama"):
                console.print("7. 🤖 Generate LLM Report")
            if env_info.get("has_docker"):
                console.print("8. 🐳 Docker Operations")
            if env_info.get("has_dvc"):
                console.print("9. 📦 DVC Operations")
                
            console.print("0. ❌ Exit")
            
            choice = console.input("\n[bold]Select an option: [/bold]")
            
            if choice == "1":
                run_command("python -c \"from src.intelligent_config import IntelligentConfig; IntelligentConfig().heal_project()\"")
            elif choice == "2":
                port = env_info.get("available_ports", [8000])[0]
                console.print(f"[bold green]Starting server on port {port}[/bold green]")
                run_command(f"python -m uvicorn main:app --host 0.0.0.0 --port {port} --reload")
            elif choice == "3":
                test()
            elif choice == "4":
                for key, value in env_info.items():
                    console.print(f"  • [cyan]{key}[/cyan]: {value}")
                console.input("\nPress Enter to continue...")
            elif choice == "5":
                config = intelligent_config.get_dynamic_config()
                console.print("[bold]Dynamic Configuration:[/bold]")
                console.print(f"  • Project: {config['project']['name']} v{config['project']['version']}")
                console.print(f"  • API Port: {config['api']['port']}")
                console.print(f"  • Models Dir: {config['paths']['models_dir']}")
                console.input("\nPress Enter to continue...")
            elif choice == "6":
                import psutil
                console.print("[bold]System Status:[/bold]")
                console.print(f"  • CPU: {psutil.cpu_percent()}%")
                console.print(f"  • Memory: {psutil.virtual_memory().percent}%")
                console.print(f"  • Disk: {psutil.disk_usage('.').percent}%")
                console.input("\nPress Enter to continue...")
            elif choice == "7" and env_info.get("has_ollama"):
                run_command("python src/llm_agent.py")
            elif choice == "8" and env_info.get("has_docker"):
                console.print("[bold]Docker Status:[/bold]")
                run_command("docker ps")
            elif choice == "9" and env_info.get("has_dvc"):
                console.print("[bold]DVC Status:[/bold]")
                run_command("dvc status")
            elif choice == "0":
                console.print("[bold green]Goodbye![/bold green]")
                break
            else:
                console.print("[bold red]Invalid option![/bold red]")
                console.input("Press Enter to continue...")
                
    except KeyboardInterrupt:
        console.print("\n[bold yellow]Interrupted by user[/bold yellow]")
    except Exception as e:
        console.print(f"[bold red]Interactive mode error: {e}[/bold red]")

@app.command(help="Deploy the application with intelligent configuration.")
def deploy(
    target: str = typer.Option("local", help="Deployment target: local, docker, k8s"),
    port: Optional[int] = typer.Option(None, help="Override port (auto-detected if not specified)")
):
    """Deploy with intelligent configuration and environment adaptation."""
    try:
        from src.deployer import Deployer
        deployer = Deployer()
        deployer.deploy(target=target, port=port)
        console.print(f"[bold green]🚀 Deployment to {target} initiated successfully.[/bold green]")
            
    except Exception as e:
        console.print(f"[bold red]Deployment failed: {e}[/bold red]")

if __name__ == "__main__":
    app()
