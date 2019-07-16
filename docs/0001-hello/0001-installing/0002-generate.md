---
title: Generating your project
---

Pakyow includes several command-line tasks for interacting with projects. Among them is the `pakyow create` task, which generates a shiny new project from a template with the most common conventions.

To generate a new project, open a terminal and run this command (just be sure to replace `{project-name}` with the name of your project):

```
pakyow create {project-name}
```

Once your project is generated, use the `cd`  command to move into the project directory and run the  `pakyow boot` task to boot the project:

```
cd {project-name} && pakyow boot
```

You should see output that looks like this:

```
162.01ms pkyw.de04ea20 | Pakyow › Development › http://localhost:3000
                       | Use Ctrl-C to shut down the environment.
```

You can access your project by navigating to [localhost:3000](https://localhost:3000) in a web browser.
