## Integra Module Development

In this tutorial we are going to look at how to create our own Integra Live modules. We will cover the two main aspects of module development: creating a new module on the Integra Database; and editing a Pd patch that will contain your new module. Before we can begin to create modules you will need to download Integra Live 1.x.x (beta)-dev-latest.tar.gz; this is the developer version of the software that displays the Pd backend concurrently with the Integra GUI. This can be found at [http://www.integralive.org/nightly/](../nightly/) You will also need to register yourself on the Integra Database. Follow this link to sign up: [http://db.integralive.org/signup](http://db.integralive.org/signup).

### Creating a new module definition on the Integra Database

Once you have logged in to the Integra Database ([http://db.integralive.org](http://db.integralive.org/)), navigate to the modules page.

![image](../../page-images/database.png "database")

Click on the 'New Definition' link; this will take you to 'Create New Module Definition' page. Once there, you will need to name you new module. In the 'Name' text box enter the name of your new module using CamelCase. In this tutorial we will call our module 'TestModule'. In the 'Label' text box you will need to give your module a 'human-readable' label i.e. Test Module. Next give a brief description of what your module will do; we will be making a delay module. Finally, from the 'Parent' menu select 'Processor'. By selecting 'Processor' as the parent module your module will automatically be configured with one audio in and one audio out. Once this is done it is time to move onto Step 2, which will take us to the 'Create New Attribute' page.

![image](../../page-images/module_def.png "module_def")

The next stage of the process will involve adding new attributes to control your module. First, we need to give our new attribute a name: we will call it delayTime. Note how we have used lowerCamelCase to name our attribute. Next we will add a description of the attribute's function. We then need to change the 'Type' menu's selection to float. This allows you to use floating point with you delayTime attribute. In the 'Minimum' and 'Maximum' text boxes you will need to add the minimum and maximum values – delay time in seconds – that your attribute will accept. We will use .01 and 20, respectively. We will also set a default value of 1, so when an instance of the module is dragged onto the canvas it will have the same initial delay time. From the 'Unit' menu choose 'second'. If you create an attribute that doesn't have have a specific unit (e.g. delay feedback), leave this set to none. Lastly, from the 'Control' menu choose what GUI widget you wish to use to control the attribute. We will be using a slider widget to control the delay time of our module. Once this is completed, we submit our new attribute to the database.

![image](../../page-images/Screen-shot-2011-06-22-at-15.35.42.png "Screen shot 2011-06-22 at 15.35.42")

Attributes need to be created for the following: mix, inLevel and outLevel. Mix will control the wet/dry balance of the audio effect, inLevel and outLevel will control the the audio in/out signal of the module, respectively. The following screenshots give details of each new attribute's parameters.

![image](../../page-images/Screen-shot-2011-06-22-at-15.56.42-297x300.png "Screen shot 2011-06-22 at 15.56.42")
![image](../../page-images/Screen-shot-2011-06-22-at-16.21.02-295x300.png "Screen shot 2011-06-22 at 16.21.02")
![image](../../page-images/Screen-shot-2011-06-22-at-15.50.43-300x300.png "Screen shot 2011-06-22 at 15.50.43")

### Editing the Pd Patch

The next stage of the process involves editing the part of our new module that takes care of audio processing: a Pure Data patch. Integra Live uses Pure Data to handle all its audio processing. First, control + click of the Integra Live 1.x.x (beta)-dev app and select show package contents. Navigate to Contents/Resources/host/integra. It is within this directory that the Pd patches for all the modules, including our new module, are contained. We will use one of the existing patches as the foundation for our new delay module. Find the file 'Delay.pd', duplicate it and rename it 'TestModule.pd'. The name of the Pd file must be the same as specified in the Integra Database. Open the 'TestModule.pd' file. You will see an inlet\~ object, an outlet\~ object, a Pd abstraction called 'handlers/ntg\_receive $1' and a Pd subpatch called 'pd delay\_module\_\_\_\_\_\_\_\_\_\_'. It is the subpatch that we will be editing.

![image](../../page-images/pdpatch.png "pdpatch")

Open the 'Pd delay\_module\_\_\_\_\_\_\_\_\_\_' subpatch. Inside you will see some more inlets, an outlet, abstractions and a subpatch called 'pd delay'. We will replace the subpatch with our own delay subpatch.

![image](../../page-images/Screen-shot-2011-06-22-at-16.16.16.png "Screen shot 2011-06-22 at 16.16.16")

Before we edit the subpatch, let us briefly discuss the three inlets and three outlets that the subpatch has. The first inlet (far left) receives the audio signal, passes it through whatever processing we have in the subpatch and passes it out of the first (far left) outlet. The third inlet receives named parameter-messages from Integra Live. In particular we will be looking at sending messages to this inlet so we can change the delay time. The third outlet sends any rejected parameter-messages to the next object in the chain. If we open the 'pd delay' subpatch we are presented with the following:

![image](../../page-images/Screen-shot-2011-06-22-at-16.51.41.png "Screen shot 2011-06-22 at 16.51.41")

We can see that the audio passes through various delay objects before exiting the subpatch: this is where the processing is done. The third inlet sends its messages to a 'route' object first. We can see that all messages prepended with 'delayTime' are sent to an object within the subpatch, and all other messages pass straight through. The arguments for root should match the name of the module attribute that we created exactly in order for changes made in the GUI to pass and effect the Pd patch. We may alter this subpatch to suit our requirements. However, we must make sure that any rejected parameter-messages are sent out of the subpatch for other subpatches/abstractions to use if necessary. Below is an example of a simple delay line that will replace the existing one. Note how the 'delwrite\~' object has an argument of 20000ms: this matches our 'Maximum' value that we set in the Integra Database (20 seconds).

![image](../../page-images/Screen-shot-2011-06-24-at-17.07.27.png "Screen shot 2011-06-24 at 17.07.27")

If we look at other abstractions in the TestModule.pd patch we will see route objects that use other attributes we created in the database i.e. 'mix', 'inLevel' and 'outLevel'. Whenever we alter these attributes in the Integra Live GUI, messages are routed to the Pure Data backend and affect the corresponding module parameters. We have now completed creating our new Integra Live module!
