#第一阶段：编译阶段
FROM python:3.10-buster AS builder

WORKDIR /app
COPY . .
RUN pip3 install -r requirements.txt
RUN python3 -m pip install build && python3 -m build

# 第二阶段：运行阶段
FROM python:3.10-slim-buster

WORKDIR /app
COPY --from=builder /app/main.py .
COPY --from=builder /app/dist/example_pkg-0.1.0.tar.gz /tmp/
RUN pip3 install /tmp/example_pkg-0.1.0.tar.gz && rm -f /tmp/example_pkg-0.1.0.tar.gz
CMD python3 main.py
