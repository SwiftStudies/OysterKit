# A text adventure using OysterKit and STLR

I wanted to create a tutorial that illustrated the complete tool-chain for someone wanting to use OysterKit to do _something_. A text adventure seems like a nice example to get started with! During this tutorial you will use the [Swift Package Manager](https://github.com/apple/swift-package-manager/blob/master/README.md) to create the executable, the command line tool for OysterKit and STLR called... imaginately... stlrc as well as your normal XCode-ing to write your code. There's a [complete GitHub repository for the final project](https://github.com/SwiftStudies/Bork). 

## Using Swift Package Manager (SPM) to create a new project

The first thing you need to do is actually create the package. To do this open Terminal.app and change to the directory where you normally keep your code, in this example I'll put mine in Documents/Code

    cd ~/Documents/Code
    mkdir Bork
    cd Bork
    swift package init --type executable
    
This creates a package of the right type and gets all the basics set-up. The first thing we need to do is add OysterKit as a dependency to the SPM package file. We'll do this using Xcode:  

    open Package.swift
    
The first thing we need to do is set up our new package so that it can access OysterKit. This pretty simple. We are going to require a specific version of OysterKit to ensure this tutorial keeps working!

    // swift-tools-version:4.0

    import PackageDescription

    let package = Package(
        name: "Bork",
        dependencies: [
            .package(url: "https://github.com/SwiftStudies/OysterKit.git", .branch("master")
        ],
        targets: [
            .target(
                name: "Bork",
                dependencies: ["OysterKit"]),
        ]
    )

SPM will need to download OysterKit from github, and we'll need to update our Xcode project. We can do that pretty easily (note you don't need to close Xcode, it will spot the changes to the project and update)

    swift package generate-xcodeproj
    
This will create the Xcode project. We can close the editor we had open for ````Package.swift```` now and open the full generated project:

	open Bork.xcodeproj

Pick File->New->File... from the main menu. Scroll through the file types until you get to "Empty File". Click OK so that you can pick a location for our empty file. You should be in the root directory of your package (Bork). Create a New Folder and call it Grammars, and in that folder create a file called Bork.stlr. 

## Defining our Grammar

We're now ready to create our grammar. Select Bork.stlr in Xcode and enter the following. We'll go through it step by step. 

    //
    // A grammar for the Bork text-adventure
    //
    

	// Vocabulary
	//
    @pin verb        = "INVENTORY" | "GO" | "PICKUP" | "DROP" | "ATTACK"
    @pin noun        = "NORTH" | "SOUTH" | "KITTEN" | "SNAKE" | "CLUB" | "SWORD"
    @pin adjective   = "FLUFFY" | "ANGRY" | "DEAD"
    @pin preposition = "WITH" | "USING"
    
    // Commands
    //
    subject     = (adjective .whitespaces)? noun
    command     = verb (.whitespaces subject (.whitespaces preposition .whitespaces subject)? )? 

You can ignore the @pin annotations for now [1], but they are important!

The first section really just establishes the vocabulary we will support. It's very very simply at this point but it should give you an idea. Let's look at the verbs

    @pin verb        = "INVENTORY" | "GO" | "PICKUP" | "DROP" | "ATTACK"
    
This line creates a new ```verb``` token that will be created whenever one of the supplied strings is found (e.g. ```GO``` or ```PICKUP```). We can then repeat the same pattern for the other types of word we support. In STLR the ```|``` operator means 'or'. So this rule could be translated into English as "create a verb token if you find INVENTORY, GO, PICKUP, DROP or ATTACK".

The first line of the command section is more interesting. As we might have two different snakes we might want to let the user describe the exact snake we want with an adjective (such as ANGRY or DEAD in our vocabulary). We create a new subject token so that we can do that

    subject     = (adjective .whitespaces)? noun

In STLR if two elements are only separated by whitespace (that is not the ```|``` or operator) it means "then". So if we ignore the brackets and question marks this rule would mean "create a subject token if you find an adjective, then a whitespace then a noun). 

We don't want to force the player to always specify an adjective so we group the first part using ```()```, and then make that group optional with the ```?``` operator. So the rule above means "create a subject token if you find an adjective followed by a whitespace then a noun. It's OK if you don't find the adjective and whitespace."

In terms of grammar concepts we don't need anymore to build the rule for any command. 

    command     = verb (.whitespaces subject (.whitespaces preposition .whitespaces subject)? )? 
    

We've got a few nested groups here but really we are saying create a ```command``` token if you match a ```verb``` which might be followed by a whitespace then ```subject``` which might be followed by a whitespace, a ```preposition```, a whitespace and another ```subject```. 

## Testing the grammar

So how do we use this grammar? How do we even know it works? Luckily I have made a command line tool to enable you to process STLR grammars, interactively test them and generate Swift source code from them. Let's start with testing, but first we'll need to build the command line tool (````stlrc````). 

I'm going to put this project in the same place as Bork, but again, you can change the first line of the commands below to be where you like to keep things! I am however assuming that the STLR and Bork directories have the same location. If you have put them in different places just make sure you specify the right location for Bork.stlr

    cd ~/Documents/Code
    git clone https://github.com/SwiftStudies/OysterKit.git
	cd OysterKit
	swift run stlrc -g ../Bork/Grammars/Bork.stlr

stlrc will start up, parse the supplied grammar and then drop into interactive mode. Try typing some commands you should see output like the below:

	swift run stlrc -g ../Bork/Grammars/Bork.stlr 
	stlrc interactive mode. Send a blank line to terminate. Parsing Bork
	ATTACK ANGRY SNAKE WITH SWORD
	command 'ATTACK ANGRY SNAKE WITH SWORD'
		verb 'ATTACK'
		subject 'ANGRY SNAKE'
			adjective 'ANGRY'
			noun 'SNAKE'
		preposition 'WITH'
		subject 'SWORD'
			noun 'SWORD'
	INVENTORY
	command 'INVENTORY'
		verb 'INVENTORY'
		
	Done

That's pretty cool. We can see it's taken the command we gave it and correctly broken up the sentences. It looks like our grammar basically works, how do we use it for our game? 

## Building an Lexer, Tokenizer, and Parser

Eurgh. Sounds like a LOT of work. Luckily OysterKit and STLR mean it's not at all. We can use the stlrc command line application to generate our Swift code. Let's head back to the terminal where we left off

	swift run stlrc generate -g ../Bork/Grammars/Bork.stlr -l swift -ot ../Bork/Sources/Bork/
	
Here we've used the generate sub-command of stlrc, given it the same grammar we've developed, and told it to generate Swift code in Bork's Sources folder. That's it! You now have a Lexer, Tokenizer, and Parser. We can do a quick test after we've updated our Bork Xcode project (remember you don't need to quit). In terminal change back into the Bork directory and do that

	swift package generate-xcodeproj
	
We can now jump back into Xcode, if you are interested take a look at the generated Bork.swift file, but you actually don't _really_ need to understand that unless you want to tinker with it. 

Open up ```main.swift```. At the moment it just prints ```"Hello, world!"``` and really we are going to want to loop around reading input from the user. Let's make those changes. 

	// Welcome the player
	print("Welcome to Bork brave Adventurer!\nWhat do you want to do now? > ", terminator: "")

	// Loop forever until they enter QUIT
	while let userInput = readLine(strippingNewline: true), userInput != "QUIT" {
	    // Process their input
    
	    // Prompt for next command
	    print("What do you want to do now? > ", terminator: "")
	}

	// Wish them on their way
	print ("Goodbye adventurer... for now.")

If you run this as you expect it welcomes you, reads in your input until you type ```QUIT```. OK, but lets use our generated language to parse that user input. Enter the following under the ```// Process their input``` comment

    // Process their input
    let parsedInput = Bork.parse(source: userInput)
    guard parsedInput.tokens.count != 0 else {
        print("I didn't understand '\(userInput)', try again. > ", terminator: "")
        continue
    }

Run it again and try interacting. We can now see if the parser understood our input or not

	Welcome to Bork brave Adventurer!
	What do you want to do now? > EAT EGGS
	I didn't understand 'EAT EGGS', try again. > GO NORTH
	What do you want to do now? > QUIT
	Goodbye adventurer... for now.
	Program ended with exit code: 0

The code you've just entered passes the user string through our Bork parser, if we get some tokens, then the command was understood, if not, then it wasn't. We can now start to _interpret_ that parsed input. Add the following line after the guard block

	    print("Your verb was \(parsedInput.tokens[0].children[0].stringValue(source: userInput))")
	    
We can now use the knowledge gained from testing this to get the first token (command) and its first child (which we know it will have because ```verb``` wasn't optional) and print out the string that matched it. 

	Welcome to Bork brave Adventurer!
	What do you want to do now? > GO NORTH
	Your verb was GO
	What do you want to do now? > QUIT
	Goodbye adventurer... for now.

This is quite exciting. We could switch on ```parsedInput.tokens[0].children[0].stringValue(source:userInput)``` and start doing different things for different verbs. However, this is going to get complicated quickly with lots of String comparisons. Our grammar guarantees that if we have the token, we will have certain values. Really we should be populating some Swift types with this information. 

## Representing a command in Swift

Using Xcode add a new Swift file in the Sources/Bork folder called ```Commands.swift```. We know from our STLR that ```command```s always have a verb, may have a ```subject```, and may have a ```preposition``` and another ```subject```. That's a pretty simple Swift type! I am using a structure as this is immutable and I'm not intending to subclass and you never know the value semantics may come in handy one day!

We could do something like this

	struct Subject {
	    let noun            : String
	    let adjective       : String?
	}

	struct Command {
	    let verb            : String
	    let subject         : Subject?
	    let preposition     : String?
	    let secondSubject   : Subject?
	}
 
But all those strings... There is going to be lot's of opportunity to mistype strings, so given at this point we have a fixed vocabulary we can create enums for the different word types and capture our vocabulary in Swift. 

Enter this code into Commands.swift

	import Foundation

	enum Verb : String {
    	case INVENTORY, GO, PICKUP, DROP, ATTACK
	}

	enum Noun : String {
    	case NORTH, SOUTH, KITTEN, SNAKE, CLUB, SWORD
	}

	enum Adjective : String {
    	case FLUFFY, ANGRY, DEAD
	}

	enum Preposition : String {
    	case WITH, USING
	}

	struct Subject {
    	let noun            : Noun
	    let adjective       : Adjective?
	}

	struct Command {
    	let verb            : Verb
    	let subject         : Subject?
    	let preposition     : Preposition?
    	let secondSubject   : Subject?
	}

I know, I know, the enums should really be camel case but bear with me. I think in this case the fact that it will make it really clear it's a vocabulary word is useful, and it makes something else easier shortly!

This is great, but wouldn't it be nice if we could just automatically populate that ```command``` struct without having to write all the code to do it? 

## Leveraging Swift 4.0 Decoders

Luckily we can. Swift 4.0 added the powerful ability to mark types with the  ```Decodable``` protocol and be able to automagically populate them from ```Data```. Let's do the first part before we leave ```Commands.swift```. Make all of the enums and structs conform to Decodable like this: 

    import Foundation
    
    enum Verb : String, Decodable {
        case INVENTORY, GO, PICKUP, DROP, ATTACK
    }
    
    enum Noun : String, Decodable {
        case NORTH, SOUTH, KITTEN, SNAKE, CLUB, SWORD
    }
    
    enum Adjective : String, Decodable {
        case FLUFFY, ANGRY, DEAD
    }
    
    enum Preposition : String, Decodable {
        case WITH, USING
    }
    
    struct Subject : Decodable {
        let noun            : Noun
        let adjective       : Adjective?
    }
    
    struct Command : Decodable {
        let verb            : Verb
        let subject         : Subject?
        let preposition     : Preposition?
        let secondSubject   : Subject?
    }

Now, I can hear what you are thinking... No-one, not Apple or any of the open-source contributors have even _tried_ to add a standard decoder for Bork. It's a travisty I know. Luckily, OysterKit can build one for you automatically. Let's replace that print statement with something more useful. Go to main.swift and add 

	import OysterKit
	
to the top of the file, then replace all of the code for processing user input with the following

    // Process their input
    do {
        let command = try ParsingDecoder().decode(Command.self, from: userInput.data(using: .utf8) ?? Data(), with: Bork.generatedLanguage)
        print(command)
    } catch {
        print("I didn't understand '\(userInput)', try again. > ", terminator: "")
        continue
    }

If all goes well, you should be able to get an interaction like the one below

    Welcome to Bork brave Adventurer!
    What do you want to do now? > PICKUP FLUFFY KITTEN
    Command(verb: Bork.Verb.PICKUP, subject: Optional(Bork.Subject(noun: Bork.Noun.KITTEN, adjective: Optional(Bork.Adjective.FLUFFY))), preposition: nil, secondSubject: nil)
    What do you want to do now? > QUIT
    Goodbye adventurer... for now.
    Program ended with exit code: 0

OysterKit automatically builds a decoder from your grammar and populates our Swift structure! This is incredibly useful. Our interpreter can now just work on a well formed Swift structure that reflects our grammar. There is one snag though...

    What do you want to do now? > ATTACK SNAKE WITH SWORD
    Command(verb: Bork.Verb.ATTACK, subject: Optional(Bork.Subject(noun: Bork.Noun.SNAKE, adjective: nil)), preposition: Optional(Bork.Preposition.WITH), secondSubject: nil)

Uh-oh. Everything seems good... until we get to ```secondSubject```. It's ```nil``` and we typed ```SWORD```. This is because by default Swift decoders look for fields with the same name... and we have two "subject" fields. Now we can't define a ```CodingKey``` as keys have to be unique. We need to change our grammar. Open up Bork.stlr and change the line that defines command to

	command   = verb (.whitespaces subject (.whitespaces preposition .whitespaces @token("secondSubject") subject)? )?

By putting the ```@token("secondSubject")``` annotation before the second instance of subject we tell STLR that instead of generating another ```subject``` token, generate one called ```secondSubject``` instead. Now we just need to rebuild the Bork.swift file. Change back into the STLR directory and type

	swift run stlrc generate -g ../Bork/Grammars/Bork.stlr -l swift -ot ../Bork/Sources/Bork/
 
This will recreate the Bork.swift file. You can now re-run in Xcode and you should get

    Welcome to Bork brave Adventurer!
    What do you want to do now? > ATTACK SNAKE WITH SWORD
    Command(verb: Bork.Verb.ATTACK, subject: Optional(Bork.Subject(noun: Bork.Noun.SNAKE, adjective: nil)), preposition: Optional(Bork.Preposition.WITH), secondSubject: Optional(Bork.Subject(noun: Bork.Noun.SWORD, adjective: nil)))
    What do you want to do now? > QUIT
    Goodbye adventurer... for now.
    Program ended with exit code: 0

That's it... we now have a well formed, type-safe, and automatically populated Swift data model for our grammar. We can actually get to work on our adventure!

## Creating a World

Create a new Swift file in Sources/Bork called `Game.swift`. We now need to create the game and its objects that the various commands the player types will be applied to. 

A number of the elements of a text adventure are named, so let's start there with a protocol. Enter the following into `Game.swift`

    protocol Named : CustomStringConvertible{
        var name : Noun              { get }
        var adjectives : [Adjective] { get }
    }

We'll extend this later with some common functionality. Next for objects in the world. Now add the following class

    class Object : Named {
        let name        : Noun
        var adjectives  : [Adjective]
        
        init(name noun:Noun, adjectives:[Adjective] = []){
            self.name = noun
            self.adjectives = adjectives
        }
    }

I chose a class because there really is only one of each object, if it is changed anywhere it should change everywhere, so reference semantics are perfect. The same is true of almost every object.

Objects need somewhere to be, so now add the Location class

    class Location : CustomStringConvertible{
        let details     : String
        var contents    : [Object]
        var exits       : [Connection]
        
        init(description:String, contents: [Object], exits:[Connection]){
            details = description
            self.contents = contents
            self.exits = exits
        }
    
        var description: String {
            var result = "You are in a \(details). "
            
            if !contents.isEmpty {
                result += "On the ground you see \(contents.list(article: .a)). "
            }
    
            if !exits.isEmpty {
                result += "Exits lead \(exits.list(article: .none)). "
            }
    
            return result
        }
    }

Locations aren't named, we want to give them rich descriptions so instead they details that can be created by the game designer. We have two array members contents is an array that will contain the various `Object`s that are in at the `Location`. We haven't defined a `Connection` yet, but it is through these the player will travel. Basically they capture the connections between places. Finally we provide a method to generate a description using the descriptive text supplied at construction, adding in lists of any objects at the location and finally the exits. These won't work yet, we will make some extensions to `Array` to add that `list` function which you'll see used many times. 

Next create the `Connection` class: 

    class Connection : Named {
        var name : Noun
        var adjectives: [Adjective] = []
        var to   : Location
        
        init(name noun:Noun, to:Location){
            self.name = noun
            self.to = to
        }
    }

Another named type (when the player types the `GO` command they are going to have to type where they want to go). Speaking of the player, let's create the `Player` class next

    class Player {
        var inventory = [Object]()
        var location  : Location
        
        init(at location:Location) {
            self.location = location
        }
    }

The player just has an inventory and a location. All that remains now is to create the game. Ideally all of this would be 

    class Game {
        var locations   = [String : Location]()
        
        let player : Player
        
        init(){
            let southRoom = Location(description: "dark stone walled room, an icy chill exudes from the every dark corner", contents: [
                Object(name: Noun.KITTEN, adjectives: [Adjective.FLUFFY]),
                Object(name: Noun.CLUB)
                ], exits: [])
            
            let northRoom = Location(description: "dark dungeon, the walls drip with moisture absorbed from the surrounding soil", contents: [
                Object(name: Noun.SNAKE),
                Object(name: Noun.SWORD)
                ], exits: [])
            
            locations["southRoom"] = southRoom
            locations["northRoom"] = northRoom
            
            southRoom.exits.append(Connection(name: Noun.NORTH, to: northRoom))
            northRoom.exits.append(Connection(name: Noun.SOUTH, to: southRoom))
    
            player = Player(at: southRoom)
        }
    }

For the purposes of this tutorial, I've made the game fixed with the map created in the `init()` method. However, this could easily be changed to load from a file. The class itself just has members for locations and a player. In the `init()` method we create two locations, add them to the `Game` and connect them. That's it. Now let's make it come alive!

## Interpreting Commands

In this tutorial we are creating a really simple text adventure. However, all of the principles would apply if we were creating an interpreter for a program language (or even a compiler). We need to take instruction the player types, and execute it. The advantage of doing it this way is we can keep it simple. 

Create a new Swift file called `Interpreter.swift` in `Sources/Bork`. Everything in this section will be added to that file. First we create a class called `Interpreter`. It has a single method `interpret` that take a command and a game, and applies that command if it's _semantically_ valid to the game world. Semantic is adjective that relates to meaning in a language. For example, `GO EGG` is valid syntactically (the structure, VERB NOUN) but not semantically (it doesn't actually _mean_ anything). In the context of our example, neither does `GO` on its own. You have to `GO` somewhere. We could actually have built this into our grammar, but I wanted to keep that simple to begin with. 

    class Interpreter {
        /**
        Interpret the supplied command in the context of a particular game. Any messages will be
        created and printed directly, and if the action can be completed the impact on the game
        will be evaluated.
        */
        public func interpret(_ command:Command, inGame game:Game){
            switch command.verb {
            case .INVENTORY:
                game.player.carrying()
            case .GO:
                guard let subject = command.subject else {
                    print("Where do you want to go?")
                    return
                }
                game.player.go(subject)
            case .PICKUP:
                guard let subject = command.subject else {
                    print("What do you want to pick up?")
                    return
                }
                game.player.pickup(subject)
            case .DROP:
                guard let subject = command.subject else {
                    print("What do you want to drop?")
                    return
                }
                game.player.drop(subject)
            case .ATTACK:
                guard let victim = command.subject else {
                    print("What do you want to attack?")
                    return
                }
                
                guard let weapon = command.secondSubject else {
                    print("What do you want to attack with?")
                    return
                }
    
                game.player.attack(victim, with: weapon)
            }
        }
    } 

The `interpret` method is really very simple. It `switch`es on the verb, ensuring that if it requires a subject that there is one. If you look at the `.INVENTORY` case you can see it does no checks because it doesn't require any additional information. If you are wondering where the `Player` functions are that are being called, you'll see those shortly in an extension [2]. The pattern is very similar for each command, we ensure we have all the information needed to try and perform the verb, and then call a method on player to actually enact that verb. 

Here's the extension for `Player`...

    fileprivate extension Player {
        func pickup(_ subject:Subject){
            do {
                let itemIndex = try location.contents.index(of: subject)
                let item = location.contents[itemIndex]
                switch (item.name,item.is(.DEAD)) {
                case (.KITTEN, false):
                    print("The kitten dodges you, making you look a fool")
                    return
                case (.SNAKE, false):
                    print("The snake bites you. Now you feel really stupid, and much deader.")
                    exit(0)
                default:
                    inventory.append(item)
                    location.contents.remove(at: itemIndex)
                    return
                }
            } catch {
                guard let descriptionError = error as? DescriptionError else {
                    print("Um. \(error.localizedDescription). So that happened.")
                    return
                }
                
                print("\(descriptionError.description) to PICKUP")
            }
        }
        
        func drop(_ subject:Subject){
            do {
                let itemIndex = try inventory.index(of: subject)
                let item = inventory.remove(at: itemIndex)
                
                location.contents.append(item)
            } catch {
                guard let descriptionError = error as? DescriptionError else {
                    print("Um. \(error.localizedDescription). So that happened.")
                    return
                }
                
                print("\(descriptionError.description) to DROP")
            }
        }
        
        func go(_ subject:Subject){
            do {
                let exit = try location.exits[location.exits.index(of: subject)]
                
                print("You go \(subject.noun)")
                location = exit.to
            } catch {
                guard let descriptionError = error as? DescriptionError else {
                    print("Um. \(error.localizedDescription). So that happened.")
                    return
                }
                
                print("\(descriptionError.description) to GO")
            }
        }
        
        func carrying(){
            print("You are carrying \(game.player.inventory.list(article: Article.a, ifEmpty: " a sense of entitlement, and little else."))")
        }
        
        func attack(_ victimSubject:Subject, with weaponSubject:Subject){
            let victim : Object
            do{
                victim = try location.contents[location.contents.index(of: victimSubject)]
            } catch {
                guard let descriptionError = error as? DescriptionError else {
                    print("Um. \(error.localizedDescription). So that happened.")
                    return
                }
                
                print("\(descriptionError.description) to ATTACK")
                return
            }
            let weapon : Object
            do{
                weapon = try inventory[inventory.index(of: weaponSubject)]
            } catch {
                guard let descriptionError = error as? DescriptionError else {
                    print("Um. \(error.localizedDescription). So that happened.")
                    return
                }
                
                print("\(descriptionError.description) to ATTACK with")
                return
            }
            
            switch (victim.name,weapon.name, victim.adjectives.contains(.DEAD)){
            case (Noun.KITTEN, Noun.CLUB, false):
                print("You swing at the kitten with the clumsy wooden club. It skips out the way, and mews defiantly")
            case (Noun.SNAKE, Noun.CLUB, false):
                print("You swing at the snake with the club, it darts out the way hissing.")
                if !victim.adjectives.contains(.ANGRY){
                    victim.adjectives.append(.ANGRY)
                }
            case (_,_,true):
                print("You hit the lifeless corpse with the \(weapon.name). It is deader, and you need help I can't give you.")
            case (Noun.KITTEN,Noun.SWORD, false), (Noun.SNAKE, Noun.SWORD, false):
                print("You slice at the \(victim.name) with the blade, killing it")
                if victim.name == Noun.KITTEN {
                    print("I hope you are pleased with yourself. No cake for you.")
                }
                if let index = victim.adjectives.index(of: .ANGRY){
                    victim.adjectives.remove(at: index)
                }
                victim.adjectives.append(.DEAD)
            default:
                print("You swing the \(weapon.name). The \(victim.name) appears not care.")
            }
        }
    }
    
That's a lot of code, let's look at a single method, for `go`:

        func go(_ subject:Subject){
            do {
                let exit = try location.exits[location.exits.index(of: subject)]
                
                print("You go \(subject.noun)")
                location = exit.to
            } catch {
                guard let descriptionError = error as? DescriptionError else {
                    print("Um. \(error.localizedDescription). So that happened.")
                    return
                }
                
                print("\(descriptionError.description) to GO")
            }
        }
        
Again, this is a pretty common pattern. We ensure that we can find an exit that's described by the supplied subject. If none or more than one match an `Error` is thrown which will tell the player what went wrong. If the exact exit can be applied we update the player's location and we're ready for the next command.  

The remainder of the file is a set of extensions that support the logic above.  

    extension Named {
        func matches(subject:Subject)->Bool{
            if name != subject.noun {
                return false
            }
            
            if let describedAs = subject.adjective {
                return adjectives.contains(describedAs)
            }
            
            return true
        }
        
        func matchesExactly(subject:Subject) -> Bool {
            if name != subject.noun {
                return false
            }
            
            if let describedAs = subject.adjective {
                return adjectives.contains(describedAs)
            }
            
            return adjectives.count == 0
        }
        
        func `is`(_ adjective:Adjective)->Bool {
            return adjectives.contains(adjective)
        }
        
        var description : String {
            if adjectives.isEmpty {
                return name.description
            }
            return "\(adjectives.concatenate(separator: ", ")) \(name)"
        }
    }
    
In this extension we have methods that help us match any named thing (`Object` and `Connection`) against a `Subject` that we've parsed from the player. 

 * `matches` validates the supplied noun matches the name of the instance and then ensures that at least the supplied adjective if an adjective of the named object. If there's no adjective that's fine. So KITTEN matches FLUFFY KITTEN and ANGRY KITTEN, and indeed ANGRY FLUFFY KITTEN. 
 * `matchesExactly` means that the subject is an exact match (all adjectives if present are the same). KITTEN doesn't match FLUFFY KITTEN. 
 * `is` returns true if the supplied adjective is one of the adjectives applied to the named object. FLUFFY KITTEN is FLUFFY, but not ANGRY. 
 * Finally we provide the generic implementation of `description : String` that we need to conform to `CustomStringConvertible` meaning that our actual types implementing `Named` don't need to provide one unless they want a different behaviour. 
 
Do you remember that `Error` could be thrown in the `go` function of player? Here's its implementation:
 
    enum DescriptionError : Error, CustomStringConvertible {
        case notFound(subject:Subject)
        
        case ambigious(description:Subject, matches:[Named])
        
        var description: String{
            switch self {
            case .notFound(let subject):
                return "There isn't a \(subject.adjective == nil ? "" : "\(subject.adjective!) ") \(subject.noun)"
            case .ambigious(_,let otherMatches):
                return "Did you mean \(otherMatches.list(article: .the, conjunction: .or))?"
            }
        }
    }
    
The two cases deal with either nothing matching or more than one thing (what the player described was `ambiguous`). A `description` is provided which can be directly displayed to the user, either telling them it isn't there or using that `list` method again (it's coming, I promise) to provide a list of all the things what they typed matched.  

    extension Array {
        func concatenate(separator:String)->String{
            return reduce(""){(result,element) in
                return result.count == 0 ? "\(element)" : "\(result)\(separator)\(element)"
            }
        }


        func list(article:Article, conjunction:Conjunction = .and,ifEmpty:String = "nothing", oxfordComma : Bool = false)->String{
            if isEmpty {
                return ifEmpty
            }
            var theList = ""
            for (index,element) in enumerated(){
                let elementString = "\(article.form(for: "\(element)"))"
                if index == 0 {
                    theList = "\(elementString)"
                } else if index == count-1 {
                    theList += "\(oxfordComma && index > 1 ? "," : "") \(conjunction) \(elementString)"
                } else {
                    theList += ", \(elementString)"
                }
            }
            
            return theList
        }
    }
    
The `concatenate` method is really a simple version of `list`, adding the supplied `separator` between everything in the list. This will normally be a ", " in our case. 

The `list` method is more complex, but essentially tries to do the same thing but sensitive to the rules of the English language. The article is how the description of the object is prefixed (so a, an, the). The logic for choosing `a` versus `an` is different. If there are two or more items it will use the supplied conjunction (joining word such as `and` or `or`) to connect them (or the last one). It will even insert an [Oxford comma](https://www.grammarly.com/blog/what-is-the-oxford-comma-and-why-do-people-care-so-much-about-it/) if you wish. 

Finally we extend all array's with elements conforming to `Named`. 
    
    extension Array where Element : Named {
        
        
        /**
        Returns all elements that match the `subject`
        
        - Parameter matching: The `Subject` that you are trying to find matches for
        - Returns: An array containing all matching elements
        */
        func elements(matching subject:Subject)->[Element]{
            return filter(){$0.matches(subject: subject)}
        }
        
        /**
        Returns the index of the best unambiguous match. An exception will be thrown if there are no matches,
        or if more than one element matches (that is, the subject is ambiguous).
        
        - Parameter ofMatching: The `Subject` being searched for
        - Returns: The index of the unambiguous (no other element matches) element
        */
        func index(of subject:Subject) throws ->Int{
            
            let allMatching = elements(matching: subject)
            
            switch allMatching.count {
            case 0:
                throw DescriptionError.notFound(subject: subject)
            case 1:
                for (index,element) in enumerated() {
                    if element.matches(subject: subject) {
                        return index
                    }
                }
                print("SERIOUS ERROR: After finding one match, index(of subject:Subject) failed to find that match.")
                throw DescriptionError.notFound(subject: subject)
            default:
                throw DescriptionError.ambigious(description: subject, matches: allMatching)
            }
        }
        
    
    }

There are just two functions here. The first returns a filtered version using `matches` from our `Named` extension earlier. This forms the basis of our `index` method, which returns the index of the matching `Named` element if there is just one element returned from `elements` function. Otherwise it throws an `DescriptionError` that we say `go` using earlier. That covers all cases. 

## Updating main.swift

We need to use our new world and interpreter, for ease I've supplied the full and final contents of main here. You'll note I've just added some hard code for `HELP`. One of the reasons I did it this way is that adding new verbs isn't actually very easy. We have to update the grammar, use `stlrc` to rebuild the Swift code for the parser, and then update our `Verb` enumeration with a new case too. There are better ways we could have built this (still using STLR), but for this tutorial you have everything you need to go further should you wish to. 

    import OysterKit
    import Foundation
    
    // Welcome the player
    let game = Game()
    let interpreter = Interpreter()
    print("Welcome to Bork brave Adventurer!\nType HELP for help.\n\n\(game.player.location)\n\nWhat do you want to do now? > ", terminator: "")
    
    // Loop forever until they enter QUIT
    while let userInput = readLine(strippingNewline: true), userInput != "QUIT" {
        // Provide help
        if userInput == "HELP" {
            print("You can type the following commands: \([Verb.INVENTORY, Verb.GO, Verb.PICKUP, Verb.DROP, Verb.ATTACK].list(article: Article.none))")
        } else {
            // Process their input
            do {
                let command = try ParsingDecoder().decode(Command.self, from: userInput.data(using: .utf8) ?? Data(), with: Bork.generatedLanguage)
                
                // Execute the command
                interpreter.interpret(command, inGame: game)
            } catch {
                print("\nI didn't understand '\(userInput)', try again. > ", terminator: "")
                continue
            }
        }
        
        // Prompt for next command
        print("\n\(game.player.location)\n\nWhat do you want to do now? > ", terminator: "")
    }
    
    // Wish them on their way
    print ("Goodbye adventurer... for now.")
    

## And Play!

You can now go to the command line and from the Bork package type

	swift run
	
Any you will be in your adventure. Obviously this is a very simple adventure, and some of the more interesting behaviours are hard coded (can you make the snake angry?). A real text adventure would need a richer data model where those behaviours were captured differently (state change events anyone?). As discussed earlier, we might also want to extend our vocabulary and with some small changes we could do just that making the String array used to create the rule for nouns for example read from an updated `Game` class that captured all the nouns actually used in the game. 

Please feel to play, don't forget you can just download the [complete GitHub repository for the final project](https://github.com/SwiftStudies/Bork). If you extend and expand any part of this I'd love to see the results!

--------

### Footnotes

[1]: The reason we needed those ```@pin``` annotations in the grammar was to ensure that none of the tokens get rolled up. By default OysterKit tries to minimise the number of tokens it creates (for memory and performance reasons). It can spot that if there's just a noun there's not much point in having a parent with just one child, and rolls up the child into the parent. That's not always desirable, so by pinning we can stop that happening. It's like saying "this token is important on its own". You don't really need to worry about that right now. There's an inverse as well, @void will always throw the token away (it might be the equivalent of whitespace... it is part of the rule, but you don't need it. 

[2]: I could have added these to the class directly, but I wanted to keep the controller logic separate from the data model. Either way is valid. 