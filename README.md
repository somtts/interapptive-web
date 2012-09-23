# Welcome to Authorly

## Setting up application on your machine

1. Clone the repository on your machine
2. Create a suitable `config/database.yml`
3. `bundle install`
4. `bundle exec rake db:create:all`
5. `bundle exec rake db:migrate`
6. `bundle exec rails server` starts the server

### To run all the test cases

`bundle exec rspec spec`

## Builder

### Synopsis

Builder is a custom widget framework/base class that provides a relevant API for
making and running different type of widgets, which are objects that can be 
added to the canvas. Builder abstracts cocos2d-js which is a two-dimensional 
drawing library that's primarily used functionally. In this way, Builder
provides a nice inheritable OO interface, which is great for testing and great
for reuse.

### Some important Cocos2d Concepts

First, you should see 
[this link](http://www.cocos2d.org/doc/programming_guide/basic_concepts.html)
for more information about the core concepts of Cocos.

To summarize, however:

- A **scene** is pretty self-explanatory. Think levels on a video game, or 
multiple, independent televisions screens. They're mostly independent of each 
other, but they have some logic for transitioning between each other
- The **director**, a singleton object that handles transitions between scenes, 
and handles main window instantiation in py-cocos2d;
- **Layers** are used to handle z-orientation of groups of items. Frequently are
the location where event handlers are defined, and respond to events from front 
to back until one layer handles an event.
-- **Sprites** are 2d images that can be transformed.
-- **Events** are part of a standard Subscribe pattern. In short, some items act
as emitters, which send out notifications when they receive certain stimulus. 
Other objects that have subscribed to the notifications will receive this 
notification and can chose to respond to it (called Listeners, usually).
    - Cocos uses events to specify user input, window status change, and to 
      communicate across parts of a framework (decoupling).
-- **CocosNode** is the superclass of the above (omitting the director?), and 
provides some default common functionality like positioning, controlling child
elements, time management, and rendering.

### Where to find Builder

Find it in `app/assets/javascripts/builder/`.

### How it loads

(Note: all paths are relative to `app/assets/javascripts` unless otherwise
specified.)

1. Its dependencies are loaded by application.js and then
`builder/index` is loaded.
2. This loads some hotpatches for cocos2d, and requires `builder/init`.
3. `builder/init` creates an `initBuilder` function on `window` that is
presumably called later.
4. `builder/app_delegate` sets up a namespace for Builder's instantiated
classes and deals with setting up the AppDelegate for cocos2d (why? what purpose
does this serve?)
5. `builder/builder` does the following:
    - it defines Builder, which is a subclass of cc.Layer;
    - it instantiates a new widget layer as its child;
    - it sets builder's scene to the present scene, and sets builder as the
      child of the scene;
    - sets Builder.node to an instance of Builder if #new and #init succeed;
    - sets window.Builder to Builder.

### How widgets work

1. The WidgetLayer manages widget space. It performs the following tasks too:
    - sets up a double-click watcher for the canvas;
    - defines methods for adding and removing widgets;
    - defines a method for getting a widget at a point
    - handles touch behaviour/moving and translates that into mouse behaviour.

2. The Widget parent class is what all widgets inherit from. It defines:
    - a newFromHash method that allows invocation with options and sets 
      positioning based on hash.position{.x,.y};
    - abstract mouseover/mouseout/dblclick responses;
    - abstract highlighting
    - opacity setters and getters
    - toHash, a serializer;

### How widgets are instantiated


### Questions to answer:
- what is `cc` ? -- is this just the JS namespace?
- 
