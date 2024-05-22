# Base image nginx 基础镜像
FROM nginx

# 安装依赖
RUN apt-get update -qq && apt-get -y install apache2-utils

# 定义好Nginx应该在哪里查找文件
ENV RAILS_ROOT /var/www/rails_nginx

# 设定镜像内工作目录
WORKDIR $RAILS_ROOT

# 创建存放日志文件夹
RUN mkdir log

EXPOSE 80 443
# Use the "exec" form of CMD so Nginx shuts down gracefully on SIGTERM (i.e. `docker stop`)
CMD [ "nginx", "-g", "daemon off;" ]
