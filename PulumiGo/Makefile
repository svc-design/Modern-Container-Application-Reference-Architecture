APP_NAME := PulumiGo
MAIN_FILE := main.go
ENV ?= sit
CONFIG ?= ./config/$(ENV)

.PHONY: all build run clean init up down export import ansible help

all: build

init:
	GOPROXY=https://goproxy.cn,direct go get github.com/spf13/cobra@latest
	GOPROXY=https://goproxy.cn,direct go get -u github.com/pulumi/pulumi/sdk/v3
	go mod tidy

build:
	go build -o $(APP_NAME) $(MAIN_FILE)

run:
	go run $(MAIN_FILE) --env $(ENV) up

init:
	go mod tidy

up:
	go run $(MAIN_FILE) --env $(ENV) up

down:
	go run $(MAIN_FILE) --env $(ENV) down

export:
	go run $(MAIN_FILE) --env $(ENV) export

import:
	go run $(MAIN_FILE) --env $(ENV) import

ansible:
	go run $(MAIN_FILE) --env $(ENV) ansible

clean:
	rm -f $(APP_NAME)

help:
	@echo "🔧 PulumiGo CLI Usage"
	@echo ""
	@echo "make build           编译可执行文件"
	@echo "make run             启动并部署（默认 ENV=sit）"
	@echo "make up              部署资源"
	@echo "make down            销毁资源"
	@echo "make export          导出 stack 状态"
	@echo "make import          导入 stack 状态"
	@echo "make ansible         执行 ansible playbook"
	@echo "make init            初始化依赖 (go mod tidy)"
	@echo "make clean           清理构建产物"
