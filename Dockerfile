FROM node:22 AS installer
COPY . /telecom-pfe
WORKDIR /telecom-pfe
RUN npm i -g typescript ts-node
RUN npm install --omit=dev --unsafe-perm
RUN npm dedupe --omit=dev
RUN rm -rf frontend/node_modules
RUN rm -rf frontend/.angular
RUN rm -rf frontend/src/assets
RUN mkdir logs
RUN chown -R 65532 logs
RUN chgrp -R 0 ftp/ frontend/dist/ logs/ data/ i18n/
RUN chmod -R g=u ftp/ frontend/dist/ logs/ data/ i18n/
RUN rm data/chatbot/botDefaultTrainingData.json || true
RUN rm ftp/legal.md || true
RUN rm i18n/*.json || true

ARG CYCLONEDX_NPM_VERSION=latest
RUN npm install -g @cyclonedx/cyclonedx-npm@$CYCLONEDX_NPM_VERSION
RUN npm run sbom

FROM gcr.io/distroless/nodejs22-debian12
ARG BUILD_DATE
ARG VCS_REF
LABEL maintainer="TonNom Mohamed malek turki" \
      org.opencontainers.image.title="Telecom PFE" \
      org.opencontainers.image.description="Application Telecom PFE" \
      org.opencontainers.image.authors="Mohamed Malek Turki " \
      org.opencontainers.image.vendor="Tunisie Telecom" \
      org.opencontainers.image.url="https://mon-projet-telecom-pfe" \
      org.opencontainers.image.source="https://github.com/monrepo/telecom-pfe" \
      org.opencontainers.image.revision=$VCS_REF \
      org.opencontainers.image.created=$BUILD_DATE
WORKDIR /telecom-pfe
COPY --from=installer --chown=65532:0 /telecom-pfe .
USER 65532
EXPOSE 3000
CMD ["/telecom-pfe/build/app.js"]
