---
title: Project Structure
---

Pakyow generates a complete project structure for you, following the conventions used by most projects. Using the defaults greatly reduces the decisions you have to make, helping you be more productive at the start.

> [callout] Don't have a project yet? Learn how to [generate one](doc:hello/installing/generate) &rarr;

Here's an overview of the structure you'll find in a default project:

| File&nbsp;or&nbsp;Folder | Overview                                  |
| ------------------------ | ----------------------------------------- |
| `backend/`               | Ruby code that powers your project on the server, such as controllers. |
| `frontend/`              | View templates and assets that make up the client-side parts of your project.  |
| `config/`                | Configuration files and initializers for your project. |
| `database/`              | Migrations and other supporting files for your project's data sources. |
| `lib/`                   | General purpose Ruby code that doesn't quite fit within the `backend`. |
| `public/`                | Static files you want to serve outside of the asset pipeline, such as `robots.txt`. |
| `tasks/`                 | Project tasks runnable through the command line interface. |
| `spec/`                  | The automated test suite for your project. |
| `.env`                   | Configuration used to configure Pakyow for your development environment. |
| `Gemfile`                | Where your project's Ruby dependencies are defined. |

You may not see all of these folders in a freshly generated project, but don't worry! Pakyow will generate them for you as needed.
