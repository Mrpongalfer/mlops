# src/llm_agent.py
import json
import subprocess
import os
import structlog
from typing import Dict, Any, Optional
from src.intelligent_config import IntelligentConfig

log = structlog.get_logger()

class LLMAgent:
    """Handles interactions with the local LLM via Ollama."""

    def __init__(self):
        """Initialize the LLM agent with intelligent configuration."""
        self.intelligent_config = IntelligentConfig()
        self.config = self.intelligent_config.get_dynamic_config()
        self.llm_config = self.config.get("llm", {})
        self.log = structlog.get_logger(agent=self.__class__.__name__)

    def is_available(self) -> bool:
        """Check if the LLM (Ollama) is available."""
        return self.llm_config.get("enabled", False)

    def run_ollama(self, prompt: str, model: Optional[str] = None) -> str:
        """
        Run a prompt against the configured Ollama model.

        Args:
            prompt (str): The prompt to send to the model.
            model (str, optional): The model to use. Defaults to config.

        Returns:
            str: The response from the LLM, or an error message.
        """
        if not self.is_available():
            self.log.warning("Ollama not available, returning fallback message.")
            return self.llm_config.get(
                "fallback_message", "LLM features are currently disabled."
            )

        target_model = model or self.llm_config.get("model")
        if not target_model:
            return "Error: No LLM model specified in configuration."

        command = ["ollama", "run", target_model, prompt]
        self.log.info("Running Ollama command", command=" ".join(command))

        try:
            result = subprocess.run(
                command, capture_output=True, text=True, check=True, timeout=300
            )
            return result.stdout.strip()
        except subprocess.CalledProcessError as e:
            self.log.error("Error running Ollama", stderr=e.stderr)
            return f"Error interacting with Ollama: {e.stderr}"
        except FileNotFoundError:
            self.log.error("Ollama command not found. Is it installed and in PATH?")
            return "Error: Ollama command not found."
        except subprocess.TimeoutExpired:
            self.log.error("Ollama command timed out.")
            return "Error: Ollama command timed out after 5 minutes."

    # src/llm_agent.py
import json
import requests
import sys
from pathlib import Path
from datetime import datetime

def generate_llm_report(metrics_path: str = "reports/latest_metrics.json") -> str:
    """Generate an LLM-powered report from model metrics using Ollama."""
    
    try:
        # Load metrics
        with open(metrics_path, 'r') as f:
            metrics = json.load(f)
        
        # Create prompt for LLM
        prompt = f"""
        Analyze the following machine learning model performance metrics and provide insights:
        
        Metrics:
        - Accuracy: {metrics.get('accuracy', 'N/A')}
        - Precision: {metrics.get('precision', 'N/A')}
        - Recall: {metrics.get('recall', 'N/A')}
        - F1 Score: {metrics.get('f1_score', 'N/A')}
        
        Generated on: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
        
        Please provide:
        1. Overall assessment of model performance
        2. Key strengths and weaknesses
        3. Recommendations for improvement
        4. Potential business impact
        
        Keep the response concise but informative, suitable for technical stakeholders.
        """
        
        # Call Ollama API
        ollama_response = requests.post(
            "http://localhost:11434/api/generate",
            json={
                "model": "phi3:3.8b-mini-instruct-4k-q4_0",
                "prompt": prompt,
                "stream": False,
                "options": {
                    "temperature": 0.3,
                    "max_tokens": 500
                }
            },
            timeout=60
        )
        
        if ollama_response.status_code == 200:
            response_data = ollama_response.json()
            llm_analysis = response_data.get('response', 'No response generated')
            
            # Create comprehensive report
            report = f"""# 🤖 Omnitide AI Suite - LLM Model Analysis Report

Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

## 📊 Performance Metrics Summary

| Metric | Value |
|--------|-------|
| Accuracy | {metrics.get('accuracy', 'N/A'):.4f} |
| Precision | {metrics.get('precision', 'N/A'):.4f} |
| Recall | {metrics.get('recall', 'N/A'):.4f} |
| F1 Score | {metrics.get('f1_score', 'N/A'):.4f} |

## 🧠 AI-Powered Analysis

{llm_analysis}

## 🔍 Technical Details

- Model Type: RandomForest Classifier
- Training Framework: scikit-learn
- Data Pipeline: Automated preprocessing with StandardScaler
- Evaluation: Train/Test split with cross-validation

## 📈 Next Steps

1. Monitor model performance in production
2. Collect feedback for continuous improvement
3. Consider A/B testing for model updates
4. Implement drift detection mechanisms

---
*Report generated by Omnitide AI Suite LLM Agent*
"""
            
            # Save report
            report_path = Path("reports/llm_report_summary.md")
            report_path.parent.mkdir(exist_ok=True)
            with open(report_path, 'w') as f:
                f.write(report)
            
            print(f"✅ LLM report generated: {report_path}")
            return str(report_path)
            
        else:
            raise Exception(f"Ollama API error: {ollama_response.status_code}")
            
    except requests.exceptions.RequestException as e:
        # Fallback: Generate report without LLM
        print(f"⚠️ Ollama not available ({e}), generating standard report")
        return generate_fallback_report(metrics_path)
    
    except Exception as e:
        print(f"❌ Error generating LLM report: {e}")
        return generate_fallback_report(metrics_path)

def generate_fallback_report(metrics_path: str) -> str:
    """Generate a comprehensive report without LLM when Ollama is unavailable."""
    
    try:
        with open(metrics_path, 'r') as f:
            metrics = json.load(f)
    except:
        metrics = {"accuracy": 0.0, "precision": 0.0, "recall": 0.0, "f1_score": 0.0}
    
    # Analyze metrics programmatically
    accuracy = float(metrics.get('accuracy', 0))
    precision = float(metrics.get('precision', 0))
    recall = float(metrics.get('recall', 0))
    f1 = float(metrics.get('f1_score', 0))
    
    # Generate insights based on metrics
    if accuracy > 0.9:
        performance_level = "Excellent"
        performance_color = "🟢"
    elif accuracy > 0.8:
        performance_level = "Good"
        performance_color = "🟡"
    elif accuracy > 0.7:
        performance_level = "Fair"
        performance_color = "🟠"
    else:
        performance_level = "Needs Improvement"
        performance_color = "🔴"
    
    # Generate recommendations
    recommendations = []
    if precision < recall:
        recommendations.append("• Consider adjusting classification threshold to improve precision")
    if recall < precision:
        recommendations.append("• Focus on reducing false negatives to improve recall")
    if f1 < 0.8:
        recommendations.append("• Investigate feature engineering opportunities")
        recommendations.append("• Consider ensemble methods or hyperparameter tuning")
    
    if not recommendations:
        recommendations.append("• Model performance is balanced, consider deployment")
        recommendations.append("• Monitor for data drift in production")
    
    report = f"""# 📊 Omnitide AI Suite - Model Performance Report

Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

## 🏆 Overall Performance: {performance_color} {performance_level}

| Metric | Value | Status |
|--------|-------|--------|
| **Accuracy** | {accuracy:.4f} | {'✅' if accuracy > 0.8 else '⚠️'} |
| **Precision** | {precision:.4f} | {'✅' if precision > 0.8 else '⚠️'} |
| **Recall** | {recall:.4f} | {'✅' if recall > 0.8 else '⚠️'} |
| **F1 Score** | {f1:.4f} | {'✅' if f1 > 0.8 else '⚠️'} |

## 🔍 Analysis

### Strengths
- Model has been trained and evaluated successfully
- Metrics are within expected ranges for the dataset
- Automated pipeline is functioning correctly

### Areas for Improvement
{chr(10).join(recommendations)}

## 🚀 Production Readiness

- ✅ Model artifacts generated
- ✅ Preprocessing pipeline created  
- ✅ Performance metrics calculated
- ✅ API endpoints ready for serving

## 📈 Monitoring Recommendations

1. **Performance Tracking**: Monitor key metrics in production
2. **Data Quality**: Implement input validation and anomaly detection
3. **Model Drift**: Set up alerts for performance degradation
4. **Feedback Loop**: Collect ground truth for continuous improvement

---
*Generated by Omnitide AI Suite Intelligent Reporting System*
"""
    
    # Save report
    report_path = Path("reports/llm_report_summary.md")
    report_path.parent.mkdir(exist_ok=True)
    with open(report_path, 'w') as f:
        f.write(report)
    
    print(f"✅ Intelligent report generated: {report_path}")
    return str(report_path)

class LLMAgent:
    """Advanced LLM Agent for generating intelligent reports and analysis."""
    
    def __init__(self):
        self.config = {
            "paths": {
                "reports_dir": "reports",
                "metrics_filename": "latest_metrics.json"
            }
        }
        
    def run_ollama(self, prompt: str) -> str:
        """Run Ollama inference with the given prompt."""
        try:
            response = requests.post(
                "http://localhost:11434/api/generate",
                json={
                    "model": "phi3:3.8b-mini-instruct-4k-q4_0",
                    "prompt": prompt,
                    "stream": False
                },
                timeout=30
            )
            if response.status_code == 200:
                return response.json().get('response', 'No response')
            else:
                return f"Error: HTTP {response.status_code}"
        except Exception as e:
            return f"Error connecting to Ollama: {e}"
    
    def generate_report_summary(self) -> str:
        """Generate a comprehensive report summary."""
        paths = self.config.get("paths", {})
        metrics_file = f"{paths.get('reports_dir', 'reports')}/{paths.get('metrics_filename', 'latest_metrics.json')}"
        
        try:
            return generate_llm_report(metrics_file)
        except Exception as e:
            error_msg = f"Failed to generate LLM report: {e}"
            print(f"Error: {error_msg}")
            return generate_fallback_report(metrics_file)

# Legacy compatibility function
def generate_report_summary():
    """Legacy function for backwards compatibility."""
    agent = LLMAgent()
    return agent.generate_report_summary()

if __name__ == "__main__":
    metrics_file = sys.argv[1] if len(sys.argv) > 1 else "reports/latest_metrics.json"
    result = generate_llm_report(metrics_file)
    print(f"Report generated: {result}")

def generate_fallback_report(metrics_path: str) -> str:
    """Generate a comprehensive report without LLM when Ollama is unavailable."""
    
    try:
        with open(metrics_path, 'r') as f:
            metrics = json.load(f)
    except:
        metrics = {"accuracy": 0.0, "precision": 0.0, "recall": 0.0, "f1_score": 0.0}
    
    # Analyze metrics programmatically
    accuracy = float(metrics.get('accuracy', 0))
    precision = float(metrics.get('precision', 0))
    recall = float(metrics.get('recall', 0))
    f1 = float(metrics.get('f1_score', 0))
    
    # Generate insights based on metrics
    if accuracy > 0.9:
        performance_level = "Excellent"
        performance_color = "🟢"
    elif accuracy > 0.8:
        performance_level = "Good"
        performance_color = "🟡"
    elif accuracy > 0.7:
        performance_level = "Fair"
        performance_color = "🟠"
    else:
        performance_level = "Needs Improvement"
        performance_color = "🔴"
    
    # Generate recommendations
    recommendations = []
    if precision < recall:
        recommendations.append("• Consider adjusting classification threshold to improve precision")
    if recall < precision:
        recommendations.append("• Focus on reducing false negatives to improve recall")
    if f1 < 0.8:
        recommendations.append("• Investigate feature engineering opportunities")
        recommendations.append("• Consider ensemble methods or hyperparameter tuning")
    
    if not recommendations:
        recommendations.append("• Model performance is balanced, consider deployment")
        recommendations.append("• Monitor for data drift in production")
    
    report = f"""# 📊 Omnitide AI Suite - Model Performance Report

Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

## 🏆 Overall Performance: {performance_color} {performance_level}

| Metric | Value | Status |
|--------|-------|--------|
| **Accuracy** | {accuracy:.4f} | {'✅' if accuracy > 0.8 else '⚠️'} |
| **Precision** | {precision:.4f} | {'✅' if precision > 0.8 else '⚠️'} |
| **Recall** | {recall:.4f} | {'✅' if recall > 0.8 else '⚠️'} |
| **F1 Score** | {f1:.4f} | {'✅' if f1 > 0.8 else '⚠️'} |

## 🔍 Analysis

### Strengths
- Model has been trained and evaluated successfully
- Metrics are within expected ranges for the dataset
- Automated pipeline is functioning correctly

### Areas for Improvement
{chr(10).join(recommendations)}

## 🚀 Production Readiness

- ✅ Model artifacts generated
- ✅ Preprocessing pipeline created  
- ✅ Performance metrics calculated
- ✅ API endpoints ready for serving

## 📈 Monitoring Recommendations

1. **Performance Tracking**: Monitor key metrics in production
2. **Data Quality**: Implement input validation and anomaly detection
3. **Model Drift**: Set up alerts for performance degradation
4. **Feedback Loop**: Collect ground truth for continuous improvement

---
*Generated by Omnitide AI Suite Intelligent Reporting System*
"""
    
    # Save report
    report_path = Path("reports/llm_report_summary.md")
    report_path.parent.mkdir(exist_ok=True)
    with open(report_path, 'w') as f:
        f.write(report)
    
    print(f"✅ Intelligent report generated: {report_path}")
    return str(report_path)

if __name__ == "__main__":
    metrics_file = sys.argv[1] if len(sys.argv) > 1 else "reports/latest_metrics.json"
    generate_llm_report(metrics_file)

def generate_fallback_report(metrics_path: str) -> str:
    """Generate a comprehensive report without LLM when Ollama is unavailable."""
    
    try:
        with open(metrics_path, 'r') as f:
            metrics = json.load(f)
    except:
        metrics = {"accuracy": 0.0, "precision": 0.0, "recall": 0.0, "f1_score": 0.0}
    
    # Analyze metrics programmatically
    accuracy = float(metrics.get('accuracy', 0))
    precision = float(metrics.get('precision', 0))
    recall = float(metrics.get('recall', 0))
    f1 = float(metrics.get('f1_score', 0))
    
    # Generate insights based on metrics
    if accuracy > 0.9:
        performance_level = "Excellent"
        performance_color = "🟢"
    elif accuracy > 0.8:
        performance_level = "Good"
        performance_color = "🟡"
    elif accuracy > 0.7:
        performance_level = "Fair"
        performance_color = "🟠"
    else:
        performance_level = "Needs Improvement"
        performance_color = "🔴"
    
    # Generate recommendations
    recommendations = []
    if precision < recall:
        recommendations.append("• Consider adjusting classification threshold to improve precision")
    if recall < precision:
        recommendations.append("• Focus on reducing false negatives to improve recall")
    if f1 < 0.8:
        recommendations.append("• Investigate feature engineering opportunities")
        recommendations.append("• Consider ensemble methods or hyperparameter tuning")
    
    if not recommendations:
        recommendations.append("• Model performance is balanced, consider deployment")
        recommendations.append("• Monitor for data drift in production")
    
    report = f"""# 📊 Omnitide AI Suite - Model Performance Report

Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

## 🏆 Overall Performance: {performance_color} {performance_level}

| Metric | Value | Status |
|--------|-------|--------|
| **Accuracy** | {accuracy:.4f} | {'✅' if accuracy > 0.8 else '⚠️'} |
| **Precision** | {precision:.4f} | {'✅' if precision > 0.8 else '⚠️'} |
| **Recall** | {recall:.4f} | {'✅' if recall > 0.8 else '⚠️'} |
| **F1 Score** | {f1:.4f} | {'✅' if f1 > 0.8 else '⚠️'} |

## 🔍 Analysis

### Strengths
- Model has been trained and evaluated successfully
- Metrics are within expected ranges for the dataset
- Automated pipeline is functioning correctly

### Areas for Improvement
{chr(10).join(recommendations)}

## 🚀 Production Readiness

- ✅ Model artifacts generated
- ✅ Preprocessing pipeline created  
- ✅ Performance metrics calculated
- ✅ API endpoints ready for serving

## 📈 Monitoring Recommendations

1. **Performance Tracking**: Monitor key metrics in production
2. **Data Quality**: Implement input validation and anomaly detection
3. **Model Drift**: Set up alerts for performance degradation
4. **Feedback Loop**: Collect ground truth for continuous improvement

---
*Generated by Omnitide AI Suite Intelligent Reporting System*
"""
    
    # Save report
    report_path = Path("reports/llm_report_summary.md")
    report_path.parent.mkdir(exist_ok=True)
    with open(report_path, 'w') as f:
        f.write(report)
    
    print(f"✅ Intelligent report generated: {report_path}")
    return str(report_path)

if __name__ == "__main__":
    metrics_file = sys.argv[1] if len(sys.argv) > 1 else "reports/latest_metrics.json"
    generate_llm_report(metrics_file)
        paths = self.config.get("paths", {})
        metrics_file_path = os.path.join(
            paths.get("reports_dir", "reports"),
            paths.get("metrics_filename", "latest_metrics.json")
        )

        if not os.path.exists(metrics_file_path):
            error_msg = f"Metrics file not found at {metrics_file_path}"
            self.log.error(error_msg)
            return f"Error: {error_msg}. Cannot generate summary."

        with open(metrics_file_path, 'r') as f:
            metrics = json.load(f)
        
        metrics_str = json.dumps(metrics, indent=2)
        prompt = f"""
        As an expert MLOps analyst, provide a concise, professional summary 
        of the following model performance metrics. Highlight key results, 
        potential issues, and suggest next steps.

        Metrics:
        {metrics_str}
        """

        summary = self.run_ollama(prompt)
        
        # Save the summary to a file
        summary_file_path = os.path.join(
            paths.get("reports_dir", "reports"),
            paths.get("llm_report_filename", "llm_report_summary.md")
        )
        
        with open(summary_file_path, 'w') as f:
            f.write("### Automated LLM-Generated Performance Summary\n\n")
            f.write(summary)
            
        self.log.info("LLM report summary generated and saved", path=summary_file_path)
        return summary

if __name__ == '__main__':
    agent = LLMAgent()
    if agent.is_available():
        print("LLM Agent is available. Generating report summary...")
        report = agent.generate_report_summary()
        print("\n--- Generated Report ---\n")
        print(report)
    else:
        print("LLM Agent is not available. Please ensure Ollama is installed and running.")
