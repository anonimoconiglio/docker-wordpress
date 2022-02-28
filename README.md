# Wordpress Docker Boilerplate

This is a simple boilerplate to use wordpress on a developer enviroment with docker, orchestrating everything with docker-compose. 

![carbon](https://user-images.githubusercontent.com/22715417/112973115-41f6bd80-9151-11eb-8033-365c9803bcf6.png)


## How to use it:

1. Clone this repository

2. Run `docker-compose up -d`

3. Access to your wordpress at: `http://localhost:8000`

And that's it! :rocket: 

If you already have a website on development/production do this **before** step 2: 

- Place your database dump in `/dump/database.sql.gz` (.sql or .sql.gz)
- Give executive permissions to the update db script: `chmod +x dump/update_db_siteurl_home.sh`
- Place your themes/plugins inside their respective folders[^1]
- Change `YOUR_DOMAIN.dns` inside the `.htaccess` file on `/uploads` folder


This same steps are listed inside the todoist template `csv` (in case you use todoist).

### Suggested workflow

You can place a git submodule inside `themes` folder, in order to have a separate repository to manage your theme.

You can also use a `composer.json` to manage plugins from your theme folder. This could remove the need to use `wp-cli` to install plugins. 


**Another handy idea**:
Sometimes, specially if you have an old WordPress environment installed (with a git project you have already set up), trying to dockerize everything could be painful. 

If you need to try your theme on the fly with docker (maybe try different versions of docker with it) you could set a custom directory for `themes` / `plugins` / `uploads` folder.

So instead of using this repository default directories (like `/wp-content/themes/`) you tell docker to use another directory on your local machine (the one from your project), outside this repository. 

Ex: `$HOME/web/my-old-wp-project/wp-content/themes`.

To achieve this simply create a `.env` file and use the same variables you find inside `.env.example`:

```
THEMES_DIR=$HOME/web/your_old_wordpress_project/wp-content/themes
PLUGINS_FOLDER=
UPLOADS_DIR=
```

In addition, if you have new paths to match or some complex config to apply, enable the `docker-compose` override function: simply set your override paths inside the file `docker-compose.override.example.yml` and rename the file without "example" in the name. By doing so the next time you run `docker-compose up` the program will take the contents of `docker-compose.override.yml` and apply them on top of your normal docker-compose file.

#### Sync plugins matching production environment

I have developed a handy system to match the same plugins that I have on the production environment in localhost environment (this is specially useful since this system syncs the exact plugin version number that the website is actually using).

##### Set enviroment variables:
To achive this you'll only need to set `.env` variables that you found inside `.env.example` file. They are: `HOSTNAME`, `USERNAME`, `APP_PASSWORD`.  

In order to obtain the last one, log in with your username on production, go to _Edit User_ page and create an _application password_ (this is a [new system for making authenticated requests to various WordPress APIs][app-pass-info] - consult the link for more information). You can add this password to the `.env` variable **with or without the spaces**, it doesn't matter.

Once you have set your environment variables you're ready to go!

##### Sync plugins:

1. Simply run the script `helpers/generate-plugins-script.js` 
- launch it as if it where a bash script: **there's no need to install anything via npm** it's vanilla nodejs script working as a binary! ;)  

2. Once the script finished take a look at the new file you will find inside `helpers/` directory, it's called `install-plugins.sh`.

- This are the instructions to install and activate the same plugins (with same version) on your local environment. Take a look at it, and decide which plugins install or not. You can eventually put this file inside your theme and add it to your source version control system - **by doing this way you can stop to sync all the plugins everytime** ;)

3. If you already launched your environment with docker compose, now it's time to sync the plugins in the wordpress container. In order to do so launch `helpers/sync-plugins.sh` - And that's it 🚀  

##### If you are curious on how this works under the hood:

The first script `generate-plugins-script.js` will fetch and retrieve a list of active plugins in production (thanks to the WP REST API), then it will generate a new script (this time a bash script) that will appear inside `/helpers/install-plugins.sh`. 

This second script is only a set of instructions for `wp-cli` to install this list of plugins (with exact version that you have on production). 

Once you approve your `install-plugins.sh` you can launch the sync function with `helpers/sync-plugins.sh`. 

This will run an instance of `wp-cli` inside a docker container, and inside this container it will execute the `install-plugins.sh` so it will install the specific versions of that plugins and activate them.


[app-pass-info]: https://make.wordpress.org/core/2020/11/05/application-passwords-integration-guide/ "Application Passwords on Wordpress"

[^1]: There are plenty of options for managing themes or plugins for an existing project, either you can copy files manually to respective directories (maybe pulling everything down from ftp etc...), or you can follow more advanced setups, here, in my [suggested workflow section](##suggested-workflow) I propose a system where you can connect your theme and then sync the plugins to match the exact versions you have in production.

## Dealing with permissions

Be aware that Docker Wordpress images are Debian-based, its default user is `www-data` and its user id (aka `UID`) is `33` (same for the group user id: `gid=33`). You'll see the user `www-data` from inside the container.

To work with mounted volumes on your host intance (for ex `/themes`, `/plugins`, `/uploads`), at least add yourself to the same group of the the conteinarized user. So for example you need to add yourself to supplementary group `33`:

	sudo usermod -aG 33 your-username

(in archlinux the `gid=33` correspond to the `http` group, so the command is equivalent to `sudo chmod -aG http username`)

After that you need to slightly change the permissions on the volume folders you want to work with:

	sudo chmod -R g+w wp-content

In this way your host user will be able to write files inside those folders (even on ones created by the container user), because you'll share the same group (and with the above commend you're giving write group permissions to those files). 

The only caveat is that every time your container creates a file (saying you install a new plugin from the wordpress containerized instance interface) this file will have `33:33` user owner without group permissions, so you could need to do that `chmod` command above again.

### Why this happens: 

Depending on the distribution your're using docker (**the HOST instance**) you could have other user names for the same `UID` and `GID`. So if you run `ls -al` from outside the container you'll see for example `http` user as the owner of the files, instead of `www-data` (on the contrary you'll see `www-data` if you do an `ls -al` from inside the container), this happens because linux reads the user id (UID) and Group Id (GID) values, no matter the username.

There is a more customizable way to deal with this, in case you need it.

### Customizing permissions

If you constantly need to modify files created from inside the container, you can customize permissions choosing to use a custom Dockerfile for the WordPress Image. It will change the default image user `UID` beforehand.

If that's your choice enable `Dockerfile.website` as the image for the `wordpress` container in the `docker-compose` configuration. 

```yml
  wordpress:
    build:
      context: .
      dockerfile: Dockerfile.website
      args:
        user_id: ${UID:-1000}
```
This will set `1000` as the UID for the default `www-data` user (in this case matching the Archlinux default user id). If you're using a different distro and by any change your UID is different this configuration should already take the env variable UID and adapt everything for you. In case it doesn't work modify `user_id` inside `docker-compose` to match your actual UID. e.g: `user_id: 1001`.

### Using wp-cli
If you need wp-cli then rename `docker-compose.override.example.yml` file into `docker-compose.override.yml`, clear the file and remove comments related to the `cli` service. Here you can choose your user according to the wordpress container config:

- `user: xfs` # if you're using default wordpress images | this user will match 33:33 (uid:gid)
- `user: "1000:33"` # if you use Dockerfile.website | matches www-data uid=1000

After this you could use `wp-cli` activating this through compose file:

	docker-compose run --rm cli wp your-wp-cli-commands

