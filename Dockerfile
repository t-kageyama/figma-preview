#
# VERSION               0.0.1
# author                Toru Kageyama
# dagte                 2026-01-20
#

FROM node:22-bookworm-slim

LABEL maintainer Toru Kageyama t_kageyama@hotmail.com

# edit time zone and locale settings if necessary.
ENV TZ=Asia/Tokyo
ENV DEBCONF_NOWARNINGS=yes
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN apt -q update
RUN apt install -y curl
RUN apt install -y zip
RUN apt install -y unzip
RUN apt install -y locales-all
RUN apt install -y vim
ENV LANG=ja_JP.UTF-8

RUN mkdir /home/node/figma-preview
RUN chown -R node:node /home/node

COPY --chown=node:node project.zip /home/node/
COPY assets/init-node.sh /home/node
COPY assets/postcss.config.js /home/node
COPY assets/tailwind.config.js /home/node
COPY assets/vite.config.ts /home/node
COPY assets/index.css /home/node
RUN chown node:node /home/node/*.config.js
RUN chown node:node /home/node/vite.config.ts
RUN chown node:node /home/node/index.css

RUN chmod +x /home/node/init-node.sh
RUN su - -c '/home/node/init-node.sh' node
RUN rm /home/node/init-node.sh

WORKDIR /home/node/figma-preview
USER node
EXPOSE 5173
CMD ["npm", "run", "dev", "--", "--host", "0.0.0.0", "--port", "5173"]
