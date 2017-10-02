



The Basics
--------------------------------




###Getting Familiar with Ruby 
-------------------------------
Pakyow is a Ruby Framework for the Web that utilizes the **MVC Paradigm**. If you're new to programming, we recommend you take a free course <a href ="https://www.codecademy.com/learn/ruby" target = "_blank"  > here</a>. If you're new to Ruby, check <a href ="https://learnxinyminutes.com/docs/ruby/" target ="_blank" > this </a> out for a quick start. 

Installing Pakyow and running an App on your computer is really easy, click <a href="https://www.pakyow.org/docs/start " target="_blank">here</a> to get started.

This document will help you get started with Pakyow and gives you a light crash course on web development. If you're feeling like a genius today dive straight in to the <a href="https://www.pakyow.org/docs/warmup" target="_blank">warmup tutorial </a> and start building your first Pakyow app. 

----------


###Understanding Model View Controller (MVC)
-------------

Model-View-Controller or MVC is a paradigm that is used to make the design of software easier. Any piece of software that is made to interact with a user, has what is called a view. The View defines how you  interact with the app, through the user interface. Views also dictate how information is presented. This information has to be stored somewhere; a place for information or templates (Class Definitions, Database Schemas) is called the Model.  As a developer, you need a way to manipulate the View and the Model. What if there was a way to programmatically control the view, while having access to the information in the model. A program, or script can accomplish this. This is otherwise known as the controller. In Pakyow, you write Ruby code in certain files that allow you to manipulate the view while having access to the data model.  

That is the basic idea of MVC. Many frameworks have their own interpretations of MVC depending on the way the responsibility is divided between the client and the server. Pakyow is built on the idea that most of the responsibility is on the server side, otherwise this leads to a <a href="https://medium.com/@bryanp/your-template-language-is-killing-the-web-33259fd1c3fd#.w4pbqvc82"  target="_blank">  broken web</a>. Pakyow takes this idea further to allow for cool concepts like <a href="https://www.pakyow.org/docs/overview/progressive-enhancement" target="_blank"> progressive enhancement</a>, views that are rendered on the server and kept up to date with the state of the app to allow for realtime web applications.  

> **Note:**

> - Understanding  <a href ="https://developer.mozilla.org/en-US/Learn/Getting_started_with_the_web/How_the_Web_works" target = "_blank" > how the web works</a> is not essential to getting started in web development, it helps to have a good grasp of what goes on in the background. 
>  
> - To read more about MVC, check  <a href ="https://developer.mozilla.org/en-US/Apps/Fundamentals/Modern_web_app_architecture/MVC_architecture#The_theory_behind_Model_View_Controller" target = "_blank" > this </a> out


----------


# Local Development

All apps need some way of "running", in the case of a web app, we need a server to be running on our computer, and a way to get to the web app. Pakyow takes care of this. For example, the command `bundle exec pakyow server` when executed from the terminal -- while you're in the directory of your Pakyow project -- fires up a server. Pakyow will expose your app on port <a href="http://localhost:3000" target="_blank"> localhost:3000</a> this is where the local version of your web app will run, and a place where you can test and debug the features that you've added to the app.

-------------------


###  Working The Terminal 

Using Pakyow requires you to be familiar with a terminal (command prompt for windows). You can spotlight search for terminal or you can get to it through the launch pad > other > terminal. For windows users,  you can find the command prompt through the search bar on the start menu, or by going All Apps > Command prompt. 

The terminal App that runs on your computer is actually an emulator. The interface for a computer before the advent of the Guided User Interface (GUI) looked a lot like the terminal emulator on your computer. The terminal only perceives text commands. The Terminal will complete your request by executing your command and reflecting the consequences of the command.
Here are a few basic commands for you to get started:

`ls` - lists all the files and directories in the current directory. 
`cd <name of directory>` - changes the working directory to the specified directory.
`cd .. ` - goes one step back in the directory chain. Let's say, for example, you're in the "pages" directory, which is in the "views" directory. Executing `cd ..` will land you in the "pages" directory. 

You can interact with both Ruby and Pakyow from the terminal. The above commands will be discussed in the warmup tutorial. 


-------------------
# Routing 

Routes associate certain functionality or content with a certain URL. For Example, a certain functionality or page could exist at the url localhost:3000/dosomething. Going to this URL, if the route was defined in the App, can actually do something. In a Pakyow app, a route can be defined in the routes.rb file located in the app > lib > routes.rb
A simple route looks like this: 

get '/dosomething' do 
p 'did something'
end 
If you have added this line of code in the routes.rb folder,  going to the URL localhost:3000/dosomething will print "did something" to the terminal (standard out).   
Routes in pakyow can act as the "controllers" for the app and can be used to do a multitude of things. For more info on routing in Pakyow, check out the <a href="https://www.pakyow.org/docs/routing" target=" _blank"> docs </a>on routing. 



--------------------------------

### GIT - A Version Control Tool

GIT is a tool that allows for you to track changes made to a project, through a simple work flow based on simple commands. GIT also keeps all the versions of your project in the rare case that you lose your files. Being familiar with Git's work flow will make your life as a Pakyow developer easier. It helps you to work on features independent of other features and helps you track bugs and figure out when they were introduced. Git works with most web services, and it makes it easier for Apps to be deployed to the real world. Simple Git commands are introduced in the warmup tutorial to accomplish deploying to Heroku (A Web App hosting service). If you're not familiar with GIT, check out this quick <a href="https://learnxinyminutes.com/docs/git/" target="_blank"> tutorial </a>.


#  Pakyow And MVC 



All the MVC related items can be found in the App folder in the Pakyow app. Lets take a look at the files and folders that are relevant to MVC in the App folder. 

App contains views where you will find, yes you guessed it,  the views for the Pakyow app. 
App also contains Lib, which in turn contains a few ruby files which together act as the "controller" 
routes.rb -- is where the routes for the application are defined. However, this can be kept in a separate folder depending on the size of the project. 
bindings.rb - contains the "bindings" for the project, these are simple functions that can be useful when rendering data.
helpers.rb - can contain methods that can be used in the routes.rb file. 

Lib is the folder where models can be defined, models are defined using ORMs in ruby files named the same as the model itself. 


#Ready to Go 

You are now equipped with enough information to get started on building your first Pakyow App. We recommend you go through the <a href="https://www.pakyow.org/docs/warmup" target="_blank">warmup tutorial</a> to get a grasp on Pakyow concepts. 





