# GCP Cloud Run + Supabase fullstack PHP app'

## pre requisites

- Linux Debian-based (Ubuntu) env (Windows WSL does the trick, not tried on a Mac)
- have PHP installed and in your `PATH`
- have a standard install of Docker Desktop
- have the [`gcloud` CLI](https://cloud.google.com/sdk/docs/install-sdk) installed on your machine
- `sudo apt update && sudo apt upgrade`
- `sudo apt autoremove`
- `gcloud components update`

## steps

- create a [Supabase](https://supabase.com/) project, save the password for later
- initiate a git project as a private repo and push it online
- create a `docker-compose.yml` file
- find a suitable Docker image for `pgAdmin` on DockerHub
- create a dockerized `pgAdmin` instance locally
- connect to the local `pgAdmin` instance
- follow the [Supabase docs](https://supabase.com/docs/guides/database/connecting-to-postgres#connecting-with-ssl) to establish a connection with the Supabase DB server
  - put db credentials in a `.env` file
  - register a Postgres server with `pgAdmin` giving it the right credentials
- dockerize a single container PHP app' with a `public/index.php` as an entry point
  - create `public/index.php`
  - create a `Dockerfile`
  - docker ignore the `.git` folder
  - initiate a composer project with `vlucas/phpdotenv` package
  - change the `/src` mapping to `App\\` in `composer.json`
  - git and docker ignore the `vendor` folder
  - run a `composer install --ignore-platform-reqs`
  - add the Composer stage to the Dockerfile using a recent tag
  - create a PHP service in the application stack
  - create a basic Apache conf file
  - write the PHP Apache Dockerfile so it uses this conf. using [these guidelines](https://cloud.google.com/run/docs/quickstarts/build-and-deploy/deploy-php-service)
  - create a `local.Dockerfile` without the opcache conf and the prod. so you can work easily in dev
  - add xdebug conf to it
  - update your `docker-compose.yml` to reflect that
  - re run the application stack and go to `http://localhost` to check if app' works
- write PHP code to connect to the DB locally
  - take the habit of coding to an interface
  - create an implementation
    - connects to the db
    - sets the connection in its `setConnection()` method
    - returns the connection in its `getConnection()` method
- require the Composer autoloader in the entry point
- load the environment
- output the result of connecting to the db
- create an account/project in the GCP
- enable billing for your project if necessary
- GCP APIs that must be enabled in your project (you can do this from your GCP browser console) =>
  - `Artifact Registry API`
  - `Cloud Build API`
  - `Cloud Build API`
  - `Compute Engine API`
  - `Container Analysis API`
- [connect your GCP identity/repo to GitHub](https://cloud.google.com/build/docs/automating-builds/github/connect-repo-github)
- initialize `gcloud` CLI => `gcloud init`
- then set the project ID =>  `gcloud config set project PROJECT_ID`
- set your default region, replacing the placeholders (without the `{}`, to replace with the relevant Google Cloud region, for instance `europe-west6`) => `gcloud config set run/region {gCloudRegion}` (the full list of regions and zones is available [here](https://cloud.google.com/compute/docs/regions-zones))
- from now on we will assume you're using `europe-west6`, but of course, set this to your region/zone on following along
- authenticate your local Docker install to Artifact Registry => `gcloud auth configure-docker europe-west6-docker.pkg.dev`
- create a Docker repository in the artifact registry, give it the previously set region, it's a good practice to set labels on Cloud resources, let's call it `tests`
- build and tag the relevant Docker image locally, replacing the placeholders (replace `PROJECT_ID` with your project id) => `docker build -t europe-west6-docker.pkg.dev/PROJECT_ID/REGISTRY_REPO_NAME/IMAGE_NAME:vx.x.x .`
- check that the container works properly on port 80 locally => `docker run europe-west6-docker.pkg.dev/PROJECT_ID/REGISTRY_REPO_NAME/IMAGE_NAME:vx.x.x -p 80:80`
- push the images to the Artifact Registry, replacing the placeholders => `docker push europe-west6-docker.pkg.dev/PROJECT_ID/REGISTRY_REPO_NAME/IMAGE_NAME:vx.x.x`
- deploy your app' for the first time ! replacing the placeholders => `gcloud run deploy mytestservice --image=europe-west6-docker.pkg.dev/PROJECT_ID/REGISTRY_REPO_NAME/IMAGE_NAME:vx.x.x --port=80 --region=europe-west6 --allow-unauthenticated`
- when app' deployed, the wizard should reveal the service URL that you can visit in your browser !
- create a continuous deployment `cloudbuild.yaml` file
- now, from the GCP, set up continuous deployment from within your Cloud Run service
- a build trigger will run automatically, wait until it's over then edit the continuous deployment
- then, edit the continuous deployment
  - to run the build trigger on tagging the main branch; tags must follow the pattern `^v(\d+)\.(\d+)\.(\d+)$`
  - to detect a `cloudbuild.yaml` file
- to push a tag => `git tag vx.x.x && git push origin vx.x.x` => see another revision of your service deployed automatically
- try pushing a new tag again, see your app' working

## to go further

- create a dedicated app' db and user
- add tests
  - unit
  - integration with a dockerized local db
- use connection pooling to connect to db for better performance
- create a staging environment
- map a custom domain to your GCP Cloud Run service (create another Artifact repo + image in another region if your current region does not support domain mappings)
- write db happy/unhappy connection logs to the cloud
- enhance CI/CD pipeline (from pre commit hook on local to CI in the cloud)
  - lint code
  - run tests
- use secrets for env vars
