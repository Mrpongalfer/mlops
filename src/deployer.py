# src/deployer.py
import subprocess
import structlog
from src.intelligent_config import IntelligentConfig
from typing import Optional

log = structlog.get_logger()

class Deployer:
    """Handles application deployment to various targets."""

    def __init__(self):
        """Initialize the deployer with intelligent configuration."""
        self.intelligent_config = IntelligentConfig()
        self.config = self.intelligent_config.get_dynamic_config()
        self.project_name = self.config.get("project", {}).get("name", "omnitide-ai-suite")
        self.log = structlog.get_logger(deployer=self.__class__.__name__)

    def _run_command(self, command: list[str]):
        """Run a shell command and log the output."""
        self.log.info("Executing command", command=" ".join(command))
        try:
            # Using PIPE for stdout and stderr to capture output
            process = subprocess.Popen(
                command,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                encoding='utf-8'
            )
            
            # Stream output to logs
            if process.stdout:
                for line in iter(process.stdout.readline, ''):
                    self.log.info(line.strip(), source="subprocess")
            
            process.wait()
            
            if process.returncode != 0:
                self.log.error(
                    "Command failed",
                    command=" ".join(command),
                    return_code=process.returncode
                )
                raise subprocess.CalledProcessError(process.returncode, command)
            
            self.log.info("Command executed successfully", command=" ".join(command))

        except FileNotFoundError:
            self.log.error("Command not found", command=command[0])
            raise
        except Exception as e:
            self.log.error("An error occurred during command execution", error=str(e))
            raise

    def deploy(self, target: str = "docker", port: Optional[int] = None):
        """
        Deploy the application to the specified target.

        Args:
            target (str): The deployment target ('docker', 'local', 'k8s').
            port (int, optional): The port to expose. Defaults to config.
        """
        self.log.info("Starting deployment", target=target)
        
        # Pre-deployment healing
        self.log.info("Running pre-deployment healing...")
        healing_actions = self.intelligent_config.heal_project()
        for action in healing_actions:
            self.log.info(action, source="heal_project")

        if target == "docker":
            self.deploy_docker(port)
        elif target == "local":
            self.deploy_local(port)
        elif target == "k8s":
            self.deploy_kubernetes()
        else:
            self.log.error("Unknown deployment target", target=target)
            raise ValueError(f"Unknown deployment target: {target}")

    def deploy_docker(self, port: Optional[int] = None):
        """Build and run the application as a Docker container."""
        self.log.info("Starting Docker deployment...")
        
        image_tag = f"{self.project_name}:latest"
        
        # Build Docker image
        self._run_command(["docker", "build", "-t", image_tag, "."])
        
        # Run Docker container
        deploy_port = port or self.config.get('api', {}).get('port', 8000)
        self._run_command([
            "docker", "run", "--rm", "-d",
            "-p", f"{deploy_port}:8000",
            "--name", self.project_name,
            image_tag
        ])
        self.log.info(
            "Docker container started",
            image=image_tag,
            port=deploy_port,
            container_name=self.project_name
        )

    def deploy_local(self, port: Optional[int] = None):
        """Run the application locally using Uvicorn."""
        self.log.info("Starting local deployment...")
        deploy_port = port or self.config.get('api', {}).get('port', 8000)
        host = self.config.get('api', {}).get('host', '0.0.0.0')
        
        command = [
            "uvicorn", "main:app",
            "--host", host,
            "--port", str(deploy_port),
            "--reload"
        ]
        self._run_command(command)

    def deploy_kubernetes(self):
        """Placeholder for Kubernetes deployment."""
        self.log.warning("Kubernetes deployment is not yet implemented.")
        # Example of what it might look like:
        # self._run_command(["kubectl", "apply", "-f", "kubernetes/deployment.yaml"])
        # self._run_command(["kubectl", "rollout", "status", f"deployment/{self.project_name}"])
        print("Kubernetes deployment logic would go here.")

if __name__ == '__main__':
    # Example usage of the Deployer class
    deployer = Deployer()
    # To deploy to docker:
    # deployer.deploy(target="docker")
    # To deploy locally:
    try:
        deployer.deploy(target="local")
    except Exception as e:
        log.error("Deployment failed during local run", error=str(e))
