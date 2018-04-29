//
//     Generated by class-dump 3.5 (64 bit) (Debug version compiled Sep 17 2017 16:24:48).
//
//     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004-2015 by Steve Nygard.
//

#import "SCAppDelLocationPicker.h"


@implementation SCAppDelLocationPicker
+ (void)configureCell:(UITableViewCell *)arg1 withLocation:(SCAppDelLocation *)arg2 {

	[[arg1 textLabel] setText:[arg2 name]];
	[[arg1 detailTextLabel] setText:[NSString stringWithFormat:@"%f %f", [arg2 latitude], [arg2 longitude]]];
}

+ (void)applyInitialCellConfigurations:(UITableViewCell *)arg1 {
	[[arg1 detailTextLabel] setTextColor:[UIColor lightGrayColor]];
	[[arg1 imageView] setClipsToBounds:YES];
	[[arg1 textLabel] setFont:[UIFont systemFontOfSize:15.0]];
}
- (void)updateSearchResultsForSearchController:(UISearchController *)arg1 {
	SCAppDelLocationPickerResults *resultsController = [arg1 searchResultsController];
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.name contains[cd] %@", arg2.searchBar.text];
	NSMutableArray *locs = [self locations];
	NSArray *results = [locs filteredArrayUsingPredicate:predicate];
	[resultsController setResultLocations:results];
	[[resultsController tableView] reloadTable];
}
- (void)searchBarSearchButtonClicked:(UISearchBar *)arg1 {
	[arg1 resignFirstResponder];
}
- (void)tableView:(UITableView *)arg1 didSelectRowAtIndexPath:(NSIndexPath *)arg2 {
	[tableView deselectRowAt:indexPath animated:YES];

	SCAppDelLocation *location = nil;
	if (arg1 == [self tableView]) {
		location = [[self locations] objectAtIndex:[arg2 row]];
	} else {
		location = [[[self resultsController] resultLocations] objectAtIndex:[arg2 row]];
	}
	[self saveLocation:location];
	if (self.completionHandler) {
		self.completionHandler(location);
	}
	
}
- (UITableViewCell *)tableView:(UITableView *)arg1 cellForRowAtIndexPath:(NSIndexPath *)arg2 {
	static NSString *identifier = @"SCAppDelLocationCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        [[self class] applyInitialCellConfigurations:cell];
    }
	SCAppDelLocation *location = [[self locations] objectAtIndex:[arg2 row]];
	[[self class] configureCell:cell withLocation:location];
    return cell;


}
- (long long)tableView:(UITableView *)arg1 numberOfRowsInSection:(long long)arg2 {
	return [[self locations] count];
}
- (long long)numberOfSectionsInTableView:(UITableView *)arg1 {
	return 1;
}
- (void)setupSearchController {
	SCAppDelLocationPickerResults *locationPickerResults = [[SCAppDelLocationPickerResults alloc] init];
	[self setResultsController:locationPickerResults];
	
	UISearchController *searchController = [[UISearchController alloc] initWithSearchResultsController:[self resultsController]];
	[self setSearchController:searchController];
	[[self searchController] setSearchResultsUpdater:self];

	[[[self searchController] searchBar] sizeToFit];
	[[self tableView] setTableHeaderView:[[self searchController] searchBar]];

	[[[self resultsController] tableView] setDelegate:self];
	[[self searchController] setDelegate:self];
	[[[self searchController] searchBar] setDelegate:self];

	[self setDefinesPresentationContext:YES];
}
- (void)loadDataSources {

	NSString *cities = @"";
	if ([SCAppDelPrefs sharedInstance] isCydia]) {
		cities = @"/Library/Application Support/BX/SCOResources.bundle/SCOCities.csv";
	} else {
		cities = [[NSBundle mainBundle] pathForResource:@"Resources.bundle/SCOCities" ofType:@"csv"];
	}
	NSString *contentOfCSV = [NSString stringWithContentsOfFile:cities encoding:4 error:nil];
	if (contentOfCSV) {
		NSArray *contentSeparated = [contentOfCSV componentsSeparatedByString:@"\n"];
		[self setLocations:[NSMutableArray new]];
		if ([contentSeparated count] > 0) {
			for(NSString *city in contentSeparated) {
				NSArray *citySeparated = [city componentsSeparatedByString:@","];

				NSString *cityName = [NSString stringWithFormat:@"%@, %@", [citySeparated objectAtIndex:0], [citySeparated objectAtIndex:1]];
				NSString *countryCode = [citySeparated objectAtIndex:2];
				NSString *cityLatitude = [citySeparated objectAtIndex:3];
				NSString *cityLongitude = [citySeparated objectAtIndex:4];

				SCAppDelLocation *delLocation = [[SCAppDelLocation alloc] init];
				[delLocation setLatitude:cityLatitude];
				[delLocation setLongitude:cityLongitude];
				[delLocation setName:cityName];
				[delLocation setCountryCode:countryCode];

				[[self locations] addObject:delLocation];
			}
		}
	}
}
- (void)showPicker {
	__weak typeof(self) weakSelf = self;

    pickerViewController =
    [[KGWLocationPickerViewController alloc] initWithSucess:^(CLLocationCoordinate2D coordinate) {

    	double coLatitude = coordinate.latitude;
    	double coLongitude = coordinate.longitude;

    	SCAppDelLocation *delLocation = [[SCAppDelLocation alloc] init];

    	[delLocation setLatitude:coLatitude];
		[delLocation setLongitude:coLongitude];
		[delLocation setName:[[SCAppDelPrefs sharedInstance] localizedStringForKey:@"CUSTOM"]];
		[delLocation setCountryCode:@""];

		[weakSelf saveLocation:delLocation];
		[weakSelf.pickerViewController dismissViewControllerAnimated:NO completion:nil];

		if (self.completionHandler) {
			self.completionHandler(delLocation);
		}
        // weakSelf.locationLabel.text = [NSString stringWithFormat:@"%f, %f", coordinate.latitude, coordinate.longitude];
    }
                                                  onFailure:nil];

    UINavigationController *navigationController =
    [[UINavigationController alloc] initWithRootViewController:pickerViewController];
    [self presentViewController:navigationController
                       animated:YES
                     completion:nil];
}
- (void)dismissController {
	NSArray *viewCs = [[self navigationController] viewControllers];
	if ([viewCs count] <= 1) {
		[self dismissViewControllerAnimated:YES completion:nil];
	} else {
		[[self navigationController] popViewControllerAnimated:YES];
	}
}
- (void)saveLocation:(SCAppDelLocation *)arg1 {
	SCAppDelPrefs *delPrefs = [SCAppDelPrefs sharedInstance];
	SCOUserPrefs *userPrefs = [delPrefs userDefaults];
	[userPrefs setFloat:[arg1 latitude] forKey:@"scLocationLatitude"];
	[userPrefs setFloat:[arg1 longitude] forKey:@"scLocationLongitude"];
	[userPrefs setObject:[arg1 name] forKey:@"scLocationDescription"];
	[userPrefs synchronize];
	[delPrefs setScLastLocation:[delPrefs location]];	
}
- (void)viewDidAppear:(_Bool)arg1 {
	[super viewDidAppear:arg1];
}
- (void)dismiss {
	[self dismissViewControllerAnimated:YES completion:nil];
}
- (void)viewDidLoad {
	[super viewDidLoad];

	[[[self navigationController] navigationBar] setBarStyle:0];
	[[self tableView] setTableFooterView:[[UIView alloc] initWithFrame:CGRectZero]];
	[[self navigationItem] setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:4 target:self action:@selector(showPicker)]];
	[self setTitle:[[SCAppDelPrefs sharedInstance] localizedStringForKey:@"CITIES"]];
	[self setupSearchController];
	[self loadDataSources];

	NSArray *viewCs = [[self navigationController] viewControllers];
	if ([viewCs count] == 1) {

		[[self navigationItem] setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:0 target:self action:@selector(dismiss)]];
	}
}
@end

