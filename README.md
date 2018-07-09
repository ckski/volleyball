# Volleyball Visualization (we need a good name)

This app aims to streamline the collection, querying and visualization of volleyball match data.

---

## Starting the web app for development

Dependencies: `nodejs, npm`

`sudo apt-get install nodejs`

``` bash
# Clone the repo

$ git clone https://github.com/ckski/volleyball/

# Install the dependencies with npm

$ cd volleyball/volleyvisapp
$ npm install

# Start the app

$ npm start

```

Dependencies 

`elixir^1.5` -> See [the elixir documentation](https://elixir-lang.org/install.html) for your distribution

## Starting the elixir cowboy web server (built)

```bash
# Run the webserver

$ cd volleyvisapp
$ sudo npm install && npm run build
$ cd ..
$ sudo mix deps.get
$ sudo iex -S mix run

```

Go to localhost/volleyvisapp in a web browser. (default port: `80`)
