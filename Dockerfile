FROM python:3.11-slim

# (선택) 기본 유틸
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /work

# 의존성 설치
COPY requirements.txt /work/requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# 노트북 기본 포트
EXPOSE 8888

CMD ["bash"]
