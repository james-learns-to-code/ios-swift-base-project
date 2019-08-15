# ios-swift-base-project
Base Project for iOS with Swift

## Purpose
Provide pre-configured project for develop iOS Project with Swift.

## Implementation
* Fork or Download this project and configure what you want to do.
* Follow the step descripted below.

## Preparation

* Homebrew
* CocoaPods
* SwiftLint

## Steps

### Create Project

1. Create Xcode Project: Single View App, Swift, Include Unit Tests, Include UI Tests. Create git repository
2. Connect Git remote repository

### Init CocoaPods

1. In Terminal, move to project folder and run 'pod init'
2. Open Podfile and edit followed by this repository's Podfile
3. In Target setting, select test target and make 'Always Embed Swift Standard Libraries' option to $(inherited)
4. Run 'pod install'

### Create Analyze Target

1. In Xcode, select project setting
2. In Configuration, select '+'. Create 'Analyze' configure by Duplicate "Debug" Configuration
3. In Target menu, select target and select 'Edit Scheme'
4. In Analyze section, select build configuration to 'Analyze'
5. In Target setting, select 'Build Phase' and select '+'. Select 'New Run Script Phase'. Input script followed by this repository's xcodeproj file
6. Create .swiftlint.yml file Input script followed by this repository's .swiftlint.yml file
7. Edit code if lint shows warning

### Git ignore

1. Create .gitignore file and input script followed by this repository's .gitignore file
2. Commit and push source

## SwiftGen
If you want to use SwiftGen, change to `swift_gen` branch and follow README
