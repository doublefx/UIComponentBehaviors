======================================================================
UIComponent Behaviors - DEVELOPER INSTRUCTIONS
======================================================================

Thanks for checking out UIComponentBehaviors from Git. These instructions 
detail how to get started with your freshly checked-out source tree.

These instructions are aimed at experienced developers looking to
participate in the development of UIComponentBehaviors.

If you are new to this project or would like to know more, read the
help note bellow.

======================================================================
ONE-TIME SETUP INSTRUCTIONS
======================================================================

We'll assume you typed the following to checkout UIComponentBehaviors
(if not, adjust the paths in the following instructions accordingly):

  cd ~
  git clone git@github.com:doublefx/UIComponentBehaviors.git

Next double-check you meet the installation requirements:

 * A proper installation of a Flex IDE.
 * A proper installation of Flex SDK 4.6 or above.

======================================================================
GIT POLICIES
======================================================================

When checking into Git, you must provide a commit message.
You should not commit any IDE.

Try to avoid "git pull", as it creates lots of commit messages like
"Merge branch 'master'. You can avoid
this with "git pull --rebase". See the "Git Tips" below for advice.

======================================================================
GIT TIPS
======================================================================

Setup Git correctly before you do anything else:

  git config --global user.name "My Name"
  git config --global user.email myname@myemaildomain.com

Perform the initial checkout with this:

  git clone git@github.com:doublefx/UIComponentBehaviors.git

Let's take the simple case where you just want to make a minor change
against master. You don't want a new branch etc, and you only want a
single commit to eventually show up in "git log". The easiest way is
to start your editing session with this:

  git pull

That will give you the latest code. Go and edit files. Determine the
changes with:

  git status

You can use "git add -A" if you just want to add everything you see.

Next you need to make a commit. Do this via:

  git commit -e

The -e will cause an editor to load, allowing you to edit the message.
Every commit message should reflect the "Git Policies" above.

Now if nobody else has made any changes since your original "git
pull", you can simply type this:

  git push origin

If the result is '[ok]', you're done. If the result is '[rejected]',
someone else beat you to it. The simplest way to workaround this is:

  git pull --rebase

The --rebase option will essentially do a 'git pull', but then it will
reapply your commits again as if they happened after the 'git pull'.
This avoids verbose logs like "Merge branch 'master'".

If you're doing something non-trivial, it's best to create a branch.
Learn more about this at http://sysmonblog.co.uk/misc/git_by_example/.

======================================================================
GETTING START
======================================================================

This project is intended to be used by developpers who like to participate
to effort I started, splitting the Flex UIComponent classe into behaviors.

Before the first commit, I splitted UIComponent in 3 behaviors:
- IAutomationObject (automation)
- IStateClient2 (states, transitions, effects)
- IAdvancedStyleClient (styles)

The goal is to be able to plug behaviors into UIComponent at runtime with the
maximum of behaviors disabled by default, leaving the sub-classes enable it as
needed.
The UIComponent contructor looks like this:

public function UIComponent(statable:Boolean = STATABLE_ENABLED, 
	stylable:Boolean = STYLABLE_ENABLED, automatable:Boolean = AUTOMATION_ENABLED)

The basic methodology I used to do so, was to create a class per behavior,
implement the corresponding interface, look for the identicals functions
into UIComponents, copy it to the behavior class and use UIComponent as a
proxy (in some cases, there's a bit of refactorisation or optimization to do).

Note: I tried as well to simulate multiple inheritance using Mixins, even using 
the Interface/Include technic but in AS3, it is not allowed to add getters/setters
to the prototype and even if, retrieving an entry thru it is 5X slower than 
retrieving one using traits.

In order to shorten the build time, I use a monkey patch
technic to implements the features in UIComponent, this implies to set
-static-link-runtime-shared-libraries alias -static-rsls to true in the
compiler setting or, if you use FlashBuilder, to select 'merge into code'
option in the project properties, if you don't do it, the original 
UICompenent class will be executed instead of the one of this project.

If you have any questions, thoughts, suggestions, please use the community support 
mailing list at flex-dev@incubator.apache.org or my email address webdoublefx@gmail.com
with [UIComponentBehaviors] in the subject.

Thanks for your interest in UIComponentBehaviors!
