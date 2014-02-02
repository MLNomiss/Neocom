//
//  NCFittingCharacterPickerCharactersViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 31.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCFittingCharacterPickerCharactersViewController.h"
#import "NCFittingCharacterPickerViewController.h"
#import "NCAccountsManager.h"
#import "NCFitCharacter.h"
#import "NCTableViewCell.h"
#import "UIImageView+URL.h"
#import "UIImage+Neocom.h"
#import "NCStorage.h"
#import "NCFittingCharacterEditorViewController.h"

@interface NCFittingCharacterPickerViewController ()
@property (nonatomic, copy) void (^completionHandler)(NCFitCharacter* character);
@end


@interface NCFittingCharacterPickerCharactersViewController ()
@property (nonatomic, strong) NSMutableArray* accounts;
@property (nonatomic, strong) NSMutableArray* customCharacters;
@end

@implementation NCFittingCharacterPickerCharactersViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.refreshControl = nil;
	self.navigationItem.rightBarButtonItem = self.editButtonItem;
	
	NSMutableArray* accounts = [NSMutableArray new];
	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
										 title:NCTaskManagerDefaultTitle
										 block:^(NCTask *task) {
											 for (NCAccount* account in [[NCAccountsManager defaultManager] accounts]) {
												 if (account.characterSheet)
													 [accounts addObject:account];
											 }
										 }
							 completionHandler:^(NCTask *task) {
								 self.accounts = accounts;
								 [self.tableView reloadData];
							 }];
	
	self.customCharacters = [NSMutableArray arrayWithArray:[NCFitCharacter characters]];
}

- (void) dealloc {
	[[NCStorage sharedStorage] saveContext];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) setEditing:(BOOL)editing animated:(BOOL)animated {
	if (editing == self.editing)
		return;
	
	[super setEditing:editing animated:animated];
	double delayInSeconds = 0.0;
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
	dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
		NSIndexPath* indexPath = [NSIndexPath indexPathForRow:self.customCharacters.count inSection:1];
		if (editing)
			[self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationTop];
		else
			[self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationTop];
	});
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:@"NCFittingCharacterEditorViewController"]) {
		NCFittingCharacterEditorViewController* destinationViewController = segue.destinationViewController;
		destinationViewController.character = sender;
	}
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (section == 0)
		return self.accounts.count;
	else if (section == 1)
		return self.editing ? self.customCharacters.count + 1 : self.customCharacters.count;
	else
		return 6;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *CellIdentifier = @"Cell";
	NCTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

	if (indexPath.section == 0) {
		NCAccount* account = self.accounts[indexPath.row];
		cell.textLabel.text = account.characterSheet.name;
		cell.imageView.image = [UIImage emptyImage];
		[cell.imageView setImageWithContentsOfURL:[EVEImage characterPortraitURLWithCharacterID:account.characterID size:EVEImageSizeRetina32 error:nil]];
	}
	else if (indexPath.section == 1) {
		if (indexPath.row == self.customCharacters.count) {
			cell.textLabel.text = NSLocalizedString(@"Add Character", nil);
		}
		else {
			NCFitCharacter* character = self.customCharacters[indexPath.row];
			cell.textLabel.text = character.name;
		}
		cell.imageView.image = nil;
	}
	else {
		cell.textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"All Skills %d", nil), indexPath.row];
		cell.imageView.image = nil;
	}
	return cell;
}

- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if (section == 0)
		return NSLocalizedString(@"EVE Characters", nil);
	else if (section == 1)
		return NSLocalizedString(@"Custom Characters", nil);
	else
		return NSLocalizedString(@"Built-in Characters", nil);
}

- (UITableViewCellEditingStyle) tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == 1) {
		if (indexPath.row == self.customCharacters.count)
			return UITableViewCellEditingStyleInsert;
		else
			return UITableViewCellEditingStyleDelete;
	}
	else
		return UITableViewCellEditingStyleNone;
}

- (void) tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		NCFitCharacter* character = self.customCharacters[indexPath.row];
		[self.customCharacters removeObjectAtIndex:indexPath.row];
		[character.managedObjectContext deleteObject:character];
		[tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationMiddle];
	}
	else if (editingStyle == UITableViewCellEditingStyleInsert) {
		NCStorage* storage = [NCStorage sharedStorage];
		NCFitCharacter* character = [[NCFitCharacter alloc] initWithEntity:[NSEntityDescription entityForName:@"FitCharacter"
																					   inManagedObjectContext:storage.managedObjectContext]
											insertIntoManagedObjectContext:storage.managedObjectContext];
		character.name = [NSString stringWithFormat:@"Character %d", self.customCharacters.count];
		[self.customCharacters addObject:character];
		[tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationMiddle];
		[self performSegueWithIdentifier:@"NCFittingCharacterEditorViewController" sender:character];
	}
}

#pragma mark - Table view delegate

- (BOOL) tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
	return indexPath.section == 1;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (self.editing) {
		NCFitCharacter* character;
		if (indexPath.section == 0)
			character = [NCFitCharacter characterWithAccount:self.accounts[indexPath.row]];
		else if (indexPath.section == 1) {
			if (indexPath.row == self.customCharacters.count) {
				[self tableView:tableView commitEditingStyle:UITableViewCellEditingStyleInsert forRowAtIndexPath:indexPath];
				return;
			}
			else
				character = self.customCharacters[indexPath.row];
		}
		else
			character = [NCFitCharacter characterWithSkillsLevel:indexPath.row];
		
		if (!character.managedObjectContext) {
			[[[NCStorage sharedStorage] managedObjectContext] insertObject:character];
			[self.customCharacters addObject:character];
			[self.customCharacters sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]];
			[tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:[self.customCharacters indexOfObject:character] inSection:1]] withRowAnimation:UITableViewRowAnimationMiddle];
		}
		[self performSegueWithIdentifier:@"NCFittingCharacterEditorViewController" sender:character];

	}
	else {
		NCFitCharacter* character;
		if (indexPath.section == 0)
			character = [NCFitCharacter characterWithAccount:self.accounts[indexPath.row]];
		else if (indexPath.section == 1)
			character = self.customCharacters[indexPath.row];
		else
			character = [NCFitCharacter characterWithSkillsLevel:indexPath.row];
		
		NCFittingCharacterPickerViewController* controller = (NCFittingCharacterPickerViewController*) self.navigationController;
		controller.completionHandler(character);
	}
}

#pragma mark - NCTableViewController

- (NSString*) recordID {
	return nil;
}

@end
