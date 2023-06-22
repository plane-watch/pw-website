# Plane Watch Website
This is the [Hugo](https://gohugo.io) source for the https://plane.watch website.

## Theme
The [Blowfish](https://blowfish.page) theme is used as it's clean, flexible, uses TailwindCSS and allows for enormous flexibility with lots of included features. Please consult the docs for how to override default behavior. 

## Content
Content pages are standard Markdown with YAML FrontMatter (meta-data) used by Hugo to determine how to display a given page. Content pages should be named `index.md` and placed inside a folder named accordingly for the page below the `content/` directory.

## Development
This theme leverages TailwindCSS to provide a nicer interface for CSS development, the downside is TailwindCSS is JIT - it needs to be compiled to include the computed classes used in the content. This section will setup a development environment that provides hot-reload of the Hugo web framework and live compilation of TailwindCSS to reflect changes.

### Prerequisites
You'll need the following installed prior to development:
- Golang >= 1.19
- NodeJS >= v19

### Clone Source
Clone the source and init the submodule that pulls down the theme into `themes/blowfish`.
``` 
❯ git clone git@github.com:plane-watch/pw-website.git
❯ cd pw-website
❯ git submodule init
❯ git submodule update
```

### Install Node Dependencies
```
❯ cd ./themes/blowfish
❯ npm install
```

### Run NPM CSS Compiler
The blowfish theme ships with some convenient NPM scripts that watch for content changes and will reactively recompile the CSS. From the root of the repo (important!!), run the following
```
❯ npm run dev

> pw-website@1.0.0 dev
> NODE_ENV=development ./themes/blowfish/node_modules/tailwindcss/lib/cli.js -c ./themes/blowfish/tailwind.config.js -i ./themes/blowfish/assets/css/main.css -o ./assets/css/compiled/main.css --jit -w

Rebuilding...

Done in 315ms.
```
 This script will wait for changes and re-compile accordingly. 

 ### Run Hugo Dev Server
In a new window, you can now run Hugo to live-render the website:
```
❯ hugo serve
Start building sites …
hugo v0.113.0+extended darwin/arm64 BuildDate=unknown

                   | EN
-------------------+-----
  Pages            | 15
  Paginator pages  |  0
  Non-page files   |  0
  Static files     | 12
  Processed images |  0
  Aliases          |  0
  Sitemaps         |  1
  Cleaned          |  0

Built in 54 ms
Watching for changes in ./pw-website/{archetypes,assets,content,data,layouts,package.json,static,themes}
Watching for config changes in ./pw-website/config.toml, ./pw-website/config/_default
Environment: "development"
Serving pages from memory
Running in Fast Render Mode. For full rebuilds on change: hugo server --disableFastRender
Web Server is available at http://localhost:1313/ (bind address 127.0.0.1)
Press Ctrl+C to stop
```

## Deployment
Deploying a hugo website is easy, running `hugo` will generate a set of static assets inside the `public` directory that can be hosted from a plain old web server. Before doing this, ensure the TailwindCSS has been compiled and it present in the `assets/css/compiled` directory.