FROM klakegg/hugo:ext-ubuntu-onbuild AS builder

FROM nginx
COPY --from=builder /target /usr/share/nginx/html
