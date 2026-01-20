#
# VERSION               0.0.1

FROM node:22-bookworm-slim

LABEL maintainer Toru Kageyama t_kageyama@hotmail.com

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

COPY --chown=node:node figma-downloads/ /home/node/figma-downloads/
COPY init-node.sh /home/node
COPY postcss.config.js /home/node
COPY tailwind.config.js /home/node
COPY vite.config.ts /home/node
RUN chown node:node /home/node/*.config.js
RUN chown node:node /home/node/vite.config.ts

RUN chmod +x /home/node/init-node.sh
RUN su - -c '/home/node/init-node.sh' node
RUN rm /home/node/init-node.sh

WORKDIR /home/node/figma-preview
USER node
EXPOSE 5173
CMD ["npm", "run", "dev", "--", "--host", "0.0.0.0", "--port", "5173"]
