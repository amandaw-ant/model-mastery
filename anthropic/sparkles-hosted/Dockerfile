FROM python:3.12-slim
WORKDIR /app
COPY requirements.txt .
# To install from your organization's package index instead of public PyPI:
#   --build-arg PIP_INDEX_URL=https://<your-index>/simple
ARG PIP_INDEX_URL
RUN pip install --no-cache-dir -r requirements.txt
# checks.py and common.py are copied in from sparkles-loop/ before the build
COPY agent.py main.py signin.py tracing.py checks.py common.py ./
EXPOSE 8088
CMD ["python", "main.py"]
