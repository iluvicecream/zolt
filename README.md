# zolt

![What is Zolt](banner.png)

a tiny go web server that speaks your language. you write your pages in lua and zolt runs them for you and return it to your user. no build step, no framework, no fuss.

# Get Started

getting zolt running is really easy terminal is all you need.

```bash
curl -fsSL https://zolt-doc.perr.dev/public/asset/install-zolt.sh | bash
```

after that restart your shell (or run `source ~/.zshrc` / `source ~/.bashrc`)

make an app folder

```bash
mkdir myapp
cd myapp
```

write your first page

create `index.lua` with this content

```luau
echo("Hello, world!");
```

now run `zoltd` inside myapp directory

after that visit http://127.0.0.1:8080 in your browser. hello, world! welcome to zolt

# Documentation

Refer to here for more info about api reference [here!](https://zolt-doc.perr.dev/)

# Build from source

want to build it yourself? you'll need go.

```bash
git clone https://github.com/iluvicecream/zolt
cd zolt
go run main.go 
// or incase you want to build the binary
./BUILD.sh
```

when it finishes, you'll have the server at `dist/`.

# How it works

every request get route to either a lua executor or a static file server.
when request the server try to find the lua script and execute it using gopher lua.
if the request starts with `/public` the server will try serve the file using `./public/` directory

# Credits

- https://github.com/yuin/gopher-lua