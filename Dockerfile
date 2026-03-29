# 第一阶段：在 Go 构建环境中编译 MinDoc 二进制
# FROM golang:bookworm AS build
FROM hub.gooting.top:5443/go/golang:bookworm AS build

ARG TAG=0.0.1

# Go 编译相关环境变量
ENV GO111MODULE=on
ENV GOPROXY=https://goproxy.cn,direct
ENV CGO_ENABLED=1
ENV GOARCH=amd64
ENV GOOS=linux

# 复制源码并切换到工作目录
ADD . /go/src/github.com/mindoc-org/mindoc
WORKDIR /go/src/github.com/mindoc-org/mindoc

# 输出当前 Go 环境，便于排查构建问题
RUN go env
# 拉取并整理依赖
RUN go mod tidy -v
# 编译 Linux AMD64 可执行文件，并写入版本信息
RUN go build -v -o mindoc_linux_amd64 -ldflags "-w -s -X 'main.VERSION=$TAG' -X 'main.BUILD_TIME=`date`' -X 'main.GO_VERSION=`go version`'"
# 为后续资源裁剪准备一个默认配置文件
RUN cp conf/app.conf.example conf/app.conf
# 清理运行时不需要的源码和 CI 文件，减小中间产物体积
RUN rm appveyor.yml docker-compose.yml Dockerfile .travis.yml .gitattributes .gitignore go.mod go.sum main.go README.md simsun.ttc start.sh conf/*.go
RUN rm -rf cache commands controllers converter .git .github graphics mail models routers utils

# 验证编译出的程序可正常执行
RUN ./mindoc_linux_amd64 version

# 复制运行时仍然需要的字体和启动脚本
ADD simsun.ttc /usr/share/fonts/win/
ADD start.sh /go/src/github.com/mindoc-org/mindoc


# 第二阶段：基于 Ubuntu 组装最终运行镜像
FROM ubuntu:latest

# 使用 bash 执行 RUN，便于复用 shell 语法
SHELL ["/bin/bash", "-c"]

WORKDIR /mindoc

# 从构建阶段复制运行所需文件
COPY --from=build /usr/share/fonts/win/simsun.ttc /usr/share/fonts/win/
COPY --from=build /go/src/github.com/mindoc-org/mindoc/mindoc_linux_amd64 /mindoc/
COPY --from=build /go/src/github.com/mindoc-org/mindoc/start.sh /mindoc/
COPY --from=build /go/src/github.com/mindoc-org/mindoc/LICENSE.md /mindoc/
# 从构建阶段复制静态资源和默认资产
COPY --from=build /go/src/github.com/mindoc-org/mindoc/lib /mindoc/lib
COPY --from=build /go/src/github.com/mindoc-org/mindoc/conf /mindoc/__default_assets__/conf
COPY --from=build /go/src/github.com/mindoc-org/mindoc/static /mindoc/__default_assets__/static
COPY --from=build /go/src/github.com/mindoc-org/mindoc/views /mindoc/__default_assets__/views
COPY --from=build /go/src/github.com/mindoc-org/mindoc/uploads /mindoc/__default_assets__/uploads

# 让中文字体文件可被运行时读取
RUN chmod a+r /usr/share/fonts/win/simsun.ttc

# 将 Ubuntu 软件源替换为阿里云镜像，加快构建速度
RUN sed -i "s/archive.ubuntu.com/mirrors.aliyun.com/g" /etc/apt/sources.list /etc/apt/sources.list.d/*


# 更新软件包索引
RUN apt-get update

# 时区设置；不预设时区时，tzdata 安装会进入交互流程
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
# 禁用 apt 交互界面
ARG DEBIAN_FRONTEND=noninteractive
# 安装时区信息
RUN apt install -y --no-install-recommends tzdata
# 重新配置 tzdata，让时区设置立即生效
RUN dpkg-reconfigure --frontend noninteractive tzdata

# 安装中文字体与语言包，保证中文渲染和导出正常
RUN apt install -y fonts-wqy-microhei fonts-wqy-zenhei locales language-pack-zh-hans-base
# 生成并设置默认区域设置
RUN locale-gen "zh_CN.UTF-8"
RUN update-locale LANG=zh_CN.UTF-8
ENV LANG=zh_CN.UTF-8
ENV LANGUAGE=zh_CN:en
ENV LC_ALL=zh_CN.UTF-8

# 安装 MinDoc 导出依赖，并下载/解压 calibre
RUN apt-get install -y --no-install-recommends \
        libglx0 libegl1 libnss3 libxcomposite1 libxkbcommon0 libxdamage1 libxrandr-dev libopengl0 libxtst6 libasound2t64 libxkbfile1\
        wget xz-utils && \
    mkdir -p /tmp/calibre-cache /opt/calibre && \
    wget -O /tmp/calibre-cache/calibre-x86_64.txz -c https://download.calibre-ebook.com/7.26.0/calibre-7.26.0-x86_64.txz  --no-check-certificate && \
    tar xJof /tmp/calibre-cache/calibre-x86_64.txz -C /opt/calibre && \
    rm -rf /tmp/calibre-cache && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# 运行时环境变量：把 calibre 放进 PATH，并开启无界面渲染
ENV PATH="/opt/calibre:$PATH" \
    QTWEBENGINE_CHROMIUM_FLAGS="--no-sandbox" \
    QT_QPA_PLATFORM="offscreen"

# 验证 calibre 安装成功
RUN ebook-convert --version

# 将配置、静态资源、上传文件、运行时数据和数据库声明为可挂载目录
VOLUME ["/mindoc/conf","/mindoc/static","/mindoc/views","/mindoc/uploads","/mindoc/runtime","/mindoc/database"]

# 暴露 MinDoc 默认端口
EXPOSE 8181/tcp

# 指向项目内置时区数据，避免部分环境缺失 zoneinfo
ENV ZONEINFO=/mindoc/lib/time/zoneinfo.zip
# 确保启动脚本可执行
RUN chmod +x /mindoc/start.sh

# 容器启动时执行自定义启动脚本
ENTRYPOINT ["/bin/bash", "/mindoc/start.sh"]

# https://docs.docker.com/engine/reference/commandline/build/#options
# docker build --progress plain --rm --build-arg TAG=2.1 --tag gsw945/mindoc:2.1 .
# https://docs.docker.com/engine/reference/commandline/run/#options
# set MINDOC=//d/mindoc # windows
# export MINDOC=/home/ubuntu/mindoc-docker # linux
# docker run -d --name=mindoc --restart=always -v /www/mindoc/uploads:/mindoc/uploads -v /www/mindoc/database:/mindoc/database  -v /www/mindoc/conf:/mindoc/conf  -e MINDOC_DB_ADAPTER=sqlite3 -e MINDOC_DB_DATABASE=./database/mindoc.db -e MINDOC_CACHE=true -e MINDOC_CACHE_PROVIDER=file -p 8181:8181 mindoc-org/mindoc:v2.1
