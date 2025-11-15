Acting as a exceptional software development. Review the requirements, define the modules that the system needs to create, and then using the appropriate wireframe, genrate the flutter code, to impliment the modules one at a time, asking to build the next module.  Use the forge_ui framework as defined below, and me questions one at a time to determine approach, and select libraries for flutter as necessary.

# The 5x platform 
A High Level Platform Definition 
* Experience - is a low code solution for generating complete applications including these capabilities:

* Core
    * UI - user interface (using forge ui application description language) generates web, android and ios applications.
    * AIM - Access and Identity Management (using mqtt go auth plugin)
    * Data Store - SQL and document databases (See details below)
    * Message - Enterprise Message bus. (see details below)
    * Workflow - State Chart Management like [http://xstate.js.org](https://xstate.js.org/)

* Deploy
    * Build - Tools for rapid application development including AI assisted design 
    * Scale - part of the ci/cd process for an application that can scale without intervention Ecosystem 

* Connect
    * ERP - enterprise resource planning 
    * CRM - customer relationship management 
    * Project Management  
    * E-Commerce - Online Store 
    * Inventory
    * Crypto - Blockchain as a module 
    * Geospatial - mapping and geospatial awareness 
    * Business Intelligence - an ai enabled business intelligence system, that can collect an use an llm to query the data.
    * API Gateway - interoperate with other api systems 
    * Smarts AI Gateway - gateway to integrate various ai’s to interact with the experience and ecosystem components 

* Product Forge - A Equity Marketplace for turning ideas into businesses
    * For both custom creation and off the shelf 
    * Components (widgets, layouts, and actions) 
    * Applications (ready to launch private instances of ready to use application 
    * Additional Ecosystem components (a place for dockers that integrate with the Experience)

# 5x AI Utilization
* conversational group chat bot that gathers the technical requirements from the software team
* ai generated code
* automatic building of the code artifacts to a demo server in near realtime.

# 5x Message
* this follows the [Enterprise Messaging Patterns](https://www.enterpriseintegrationpatterns.com/patterns/messaging/) arrangements
* uses mosquitto mqtt server with the go auth plugin for access control and authentication
* access control is granted by records in the database

# 5x Data Store
* uses MQTT pub sub services to access data, with three simple topics
- load/${path} - loads a json stored at that path
- save/${path} - saves json data to the path
- data/${path} - published by the server as it changes the data

5x Theming
* Uses flutter json theme to customize components
* by default, generate a dark theme, that is modern and simple
