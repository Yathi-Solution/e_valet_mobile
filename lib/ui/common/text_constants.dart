class TextConstants {
  TextConstants._();

  static const dashboard = 'Dashboard';
  static const slots = 'Slots';
  static const parkedCar = 'Parked Car';
  static const valets = 'Valets';
  static const driversGroup = 'Drivers Group';

  /// Operator Drivers Group screen — header, actions, and member count row.
  static const String driversGroupSubtitle = 'Manage Drivers Group';
  static const String addGroupLabel = 'Add Group';
  static const String addMembersLabel = 'Add members';
  static const String groupMembersCountLabel = 'Members';

  /// Prefix when API group name is `Group 1`, `Group 2`, etc. (see grouping UI).
  static const String groupNamePrefix = 'Group';

  /// Backend i18n map keys — `GET /i18n/translations` → `translations[key]`.
  /// Keep these in sync with operator grouping UI and [ValetUtils.translatedStatusLabel].
  static const String i18nKeyDriversGroup = 'driversGroup';
  static const String i18nKeyDriversGroupSubtitle = 'driversGroupSubtitle';
  static const String i18nKeyGroupingDescription = 'groupingDescription';
  static const String i18nKeyAddGroup = 'addGroup';
  static const String i18nKeyAddGroupLabel = 'addGroupLabel';
  static const String i18nKeyAddMembers = 'addMembers';
  static const String i18nKeyAddMembersLabel = 'addMembersLabel';
  static const String i18nKeyMembers = 'members';
  static const String i18nKeyGroupNamePrefix = 'groupNamePrefix';
  static const String i18nKeyStatusAvailable = 'statusAvailable';
  static const String i18nKeyStatusOnDuty = 'statusOnDuty';
  static const String i18nKeyStatusOnBreak = 'statusOnBreak';
  static const String i18nKeyStatusOffline = 'statusOffline';
  static const String i18nKeyAvailable = 'available';
  static const String i18nKeyOnDuty = 'onDuty';
  static const String i18nKeyOnBreak = 'onBreak';
  static const String i18nKeyOffline = 'offline';

  static const carLogs = 'Car Logs';
  static const cards = 'Cards';

  /// Operator Cards tab header and subtitle.
  static const String cardsAllotmentTitle = 'Cards Allotment';
  static const String cardsAssignToEachValet = 'Assign cards to each valet';

  /// Explains why operators assign card counts per driver on the Cards tab.
  static const String cardsAllocationDescription =
      'Assign physical car numbers.';

  /// Row hint when no numbers assigned yet.
  static const String cardsNoNumbersAssigned = 'No card numbers assigned';
  static const String cardsEditAllocationTitle = 'Assigned card numbers';

  /// Error shown to a driver who tries to park/retrieve using a card not allocated to them.
  static const String driverCardNotAssigned =
      'The card number does not match with your cards. You may have taken another driver\'s card.';
  static const String driverCardsLoading =
      'Your assigned cards are still loading. Please wait a moment and try again.';
  static const String cardsAllocationHint =
      'Example: 11, 12, 13, 14, 15, 61, 21, 89, 16…';
  static const String cardsAllocationHelper =
      'Separate numbers with commas or spaces. You can paste multiple lines.';
  static const String cardsSaveAllocation = 'Save';
  static const String cardSingular = 'card';
  static const String cardsPlural = 'cards';
  static const String syncCards = 'Sync Cards';
  static const String cardsSyncedMessage = 'Cards synced';
  static const profile = 'Profile';
  static const guidelines = 'Guidelines';
  static const help = 'Help';
  static const overTime = 'Over Time';
  static const String hours = 'Hours';
  static const String minutes = 'Minutes';
  static const String hourUnit = 'hour';
  static const String hoursUnit = 'hours';
  static const String minuteUnit = 'minute';
  static const String minutesUnit = 'minutes';
  static const String overtimeDescription =
      'Enter overtime duration for each valet';
  static const String overtimeNote =
      'Note: The number you enter will be considered in minutes.';
  static const String overtimeInputHint = 'Enter numbers only';
  static const String overtimeEnterNumbers =
      'Please enter a value (numbers only)';
  static const String overtimeConfirmTitle = 'Confirm Overtime';
  static const String overtimeGranted = 'Overtime granted';
  static const String overtimeExpiresAt = 'Overtime till';

  /// Template for overtime confirmation popup.
  ///
  /// Important: this must contain `{valetName}` and `{minutes}` placeholders,
  /// because `OvertimeConfirmDialog` replaces `{minutes}` with a formatted
  /// "hours + minutes" string while still submitting raw minutes to backend.
  static String overtimeConfirmMessage(String valetName, int minutes) =>
      'You have extended the {valetName} time {minutes} more.';
  static const String overtimeNoAvailableDrivers =
      'No available drivers for now';
  static const String operatorResponsibilities = 'Operator Responsibilities';
  static const logout = 'Logout';

  static const emptyText = '';
  static const headerWelcome = 'Welcome,';
  static const headerName = 'Sample Name';

  // QR Scanner
  static const orEnterKey = 'Or Enter Key';
  static const String scanQr = 'Scan QR';
  static const String scanCardLabel = 'Scan Card';
  static const String scanWhatsAppQrInstruction =
      'Scan the WhatsApp QR code from the customer valet card';

  // Manual Request
  static const pleaseEnterCardNumber = 'Please enter a card number';
  static const pleaseEnterValidCardNumber = 'Please enter a valid card number';
  static const manualRequest = 'MANUAL REQUEST';
  static const processingText = 'PROCESSING...';
  static const failedToCreateRequest = 'Failed to create manual request...';

  // Assign Driver
  static const failedToAssignDriver = 'Failed to assign driver';

  static const welcomeTitle = 'Welcome to Café Niloufer Valet Service';
  static const welcomeSubtitle = "I'm Sample Name, your valet for today.";
  static const qrInstruction =
      'Please scan this QR code so I can take care of your car and keep you updated on WhatsApp.';

  static const statusOnlineMessage = 'You are now Online';
  static const statusOfflineMessage = 'You are now Offline';
  static const breakEnabledMessage = 'Break mode enabled';
  static const breakDisabledMessage = 'Break mode disabled';

  // Validation Messages
  static const String validationEmailRequired = 'Please enter your email';
  static const String validationEmailInvalid = 'Please enter a valid email';
  static const String validationPhoneRequired =
      'Please enter your Phone Number';
  static const String validationPasswordRequired = 'Please enter your password';
  static String validationPasswordMinLength(int minLength) =>
      'Password must be at least $minLength characters';
  static const String loginAccessDenied =
      'Access denied. Only ADMIN or PILOT users can access this application.';

  /// Shown when user is logged out because the account was used on another device.
  static const String loggedOutAnotherDevice =
      'You have been logged out because your account was used on another device. Please sign in again.';

  // Default Hint Texts
  static const String defaultEmailHint = 'Enter your email';
  static const String defaultPasswordHint = 'Enter your password';

  // Login
  static const String loginPrompt = 'Please Login to Continue';
  static const String phoneNumberLabel = 'Phone Number';
  static const String phoneNumberHint = 'Enter Phone Number';
  static const String passwordLabel = 'Password';
  static const String passwordHint = 'Enter Your Password';
  static const String loginButton = 'Login';
  static const String loginButtonLoading = 'Logging in...';
  static const String forgotPassword = 'Forgot Password?';

  // Forgot Password
  static const String forgotPasswordTitle = 'Forgot Password';
  static const String forgotPasswordDescription =
      'Enter your phone number to receive OTP';
  static const String sendResetInstructions = 'Send OTP';
  static const String sendResetInstructionsLoading = 'Sending...';

  // Password Reset OTP
  static const String enterOtpTitle = 'Enter OTP';
  static const String enterNewPasswordTitle = 'Enter New Password';
  static String otpSentTo(String phoneNumber) =>
      'We sent a 6-digit code to $phoneNumber';
  static const String verifyOtp = 'Verify OTP';
  static const String verifyingOtp = 'Verifying...';
  static const String otpVerifiedSetPassword =
      'OTP verified. Set a new password.';
  static const String enterSixDigitOtp = 'Please enter the 6-digit OTP.';
  static const String resetTokenMissing =
      'Reset token missing. Please request OTP again.';
  static const String genericError = 'Something went wrong. Please try again.';
  static const String resendOtp = 'Resend OTP';
  static const String resendingOtp = 'Resending...';
  static const String newPasswordLabel = 'New Password';
  static const String newPasswordHint = 'Enter your new password';
  static const String submitNewPassword = 'Submit New Password';
  static const String submittingNewPassword = 'Submitting...';
  static const String newPasswordRequired = 'Please enter a new password.';
  static const String passwordRequirements =
      'Password must contain uppercase, lowercase, number and special character and more than 8 characters';
  static const String validationPasswordNoSpaces =
      'Password cannot contain spaces';

  // Driver Home & Profile
  static const String driverHomeTitle = 'Driver Home';
  static const String driverFallbackName = 'Driver';
  static const String userFallbackName = 'User';
  static const String hiGreeting = 'Hi';
  static String readyToParkMessage(String driverName) => 'Hi $driverName,';
  static const String requestedAt = 'Requested at';
  static const String scanKeyTagInstruction =
      'Scan the key tag to start the parking process.';
  static const String parkVehicle = 'Park Vehicle';
  static const String retrieveVehicle = 'Retrieve Vehicle';
  static const String vehicleDetailsTitle = 'Vehicle details';
  static const String vehicleDetailsHint =
      'Enter card number or scan the QR in the card below.';

  /// Hint for the parking/photo screen (after tag/QR submit): car photo only.
  static const String vehicleDetailsParkingPhotoHint =
      'Capture a photo of the car.';
  static const String tapToCaptureVehiclePhoto =
      'Tap to capture vehicle photo';
  static const String previewDoneButton = 'Done';
  static const String scanTabLabel = 'Scan';
  static const String typeIdNumberTabLabel = 'ID Number';
  static const String typeParkingNumberTabLabel = 'Card Number';
  static const String locationVehicleNumber = 'Location and Vehicle Number';
  static const String carPhoto = 'Car Photo';
  static const String enterTagNumberLink = 'Or enter the tag number';
  static const String pleaseTurnOnlineToPark =
      'Please Turn Online To Park a Car';
  static const String cannotParkCarOffline =
      'Can\'t park Car unless you turn Online';

  // Clock-in too far (after login)
  static const String clockInTooFarTitle = 'Too Far From Outlet';
  static const String clockInTooFarSubtitle =
      'You are too far from the check-in location to go online.';
  static const String submitButton = 'Submit';
  static const String phoneLabel = 'Phone';
  static const String emailLabel = 'Email';

  /// Selected outlet from login (operator/scanner/driver session).
  static const String profileOutletLabel = 'Outlet';
  static const String usernameLabel = 'Username';
  static const String joinedLabel = 'Joined';
  static const String resetPassword = 'Reset Password';
  static const String profileMenuTitle = 'Profile';
  static const String guidelinesMenuTitle = 'Guidelines';
  static const String helpMenuTitle = 'Help';
  static const String logoutMenuTitle = 'Logout';

  // Help screen
  static const String helpContactSupport = 'Contact & Support';
  static const String helpCommonIssues = 'Common Issues';
  static const String helpLoadingContacts = 'Loading contacts...';
  static const String helpNoContacts = 'No support contacts available';
  static const String helpFailedToLoad = 'Failed to load support contacts';
  static const String helpSupportTeam = 'Support Team';

  // Change Password Dialog
  static const String passwordChangedSuccess = 'Password changed successfully';
  static const String currentPasswordLabel = 'Current Password';
  static const String currentPasswordHint = 'Enter your current password';
  static const String confirmNewPasswordLabel = 'Confirm New Password';
  static const String confirmNewPasswordHint = 'Confirm your new password';
  static const String close = 'Close';
  static const String update = 'Update';

  // Block Dropdown
  static const String blockLabel = 'Block';
  static String selectLabel(String label) => 'Select $label';
  static const String searchBlockHint = 'Search block...';

  // Footer
  static const String poweredBy = 'Powered By';

  // QR Code Scanner
  static const String processingQrCode = 'Processing QR Code...';
  static const String scannedDataLabel = 'Scanned Data:';
  static const String scannedLabel = 'Scanned:';
  static const String errorProcessingQrCode = 'Error Processing QR Code';
  static const String qrCodeScannedSuccessfully =
      'QR Code scanned successfully';

  // Break Messages
  static const String takingBreak = 'Taking a Break';
  static const String relaxAndRestart = 'Relax and Restart!';
  static const String endBreak = 'End Break';

  // Manual Tag Entry (shown as Card Number on Vehicle details screen)
  static const String enterTagNumberTitle = 'Enter the Tag Number to Proceed';
  static const String tagNumberLabel = 'Card Number';
  static const String tagNumberHint = 'Enter card number';
  static const String scanTagNumberLink = 'Or scan the tag number';

  // Third screen (after QR/tag submit) - Parking location for tag flow
  static const String enterParkingLocationToProceed =
      'Enter the Parking Location to Proceed';
  static const String parkingLocationLabel = 'Parking Location';
  static const String parkingLocationHint =
      'Enter parking spot or location (e.g. A-12)';
  static const String pleaseEnterParkingLocation =
      'Please enter parking location';
  static const String vehicleNumberLabel = 'Vehicle Number';
  static const String vehicleNumberHint = 'Enter vehicle number (digits only)';
  static const String pleaseEnterVehicleNumber = 'Please enter vehicle number';
  static const String pleaseCompleteParkingProcess =
      'Please complete the parking process.';

  // QR Status Messages
  static const String scannedSuccess = 'Scanned Success';
  static const String cardNumberLabel = 'Card Number';
  static const String cardLabel = 'Card: ';
  static const String rescanButton = 'Rescan';
  static const String errorLabel = 'Error';

  // Camera Screen
  static const String captureCarInstruction =
      'Capture the car clearly with location\nlandmarks';
  static const String captureAPhotoOfTheCar = 'Capture a photo of the car';
  static const String captureTheCarClearlyWithLocationLandmarks =
      'Capture the car clearly with location landmarks';
  static const String photoMode = 'PHOTO MODE';
  static const String cameraNotAvailable = 'No camera available on this device';
  static const String errorInitializingCamera = 'Error initializing camera';
  static const String errorTogglingFlash = 'Error toggling flash';
  static const String cameraNotReady = 'Camera not ready';
  static const String errorCapturingPhoto = 'Error capturing photo';
  static const String photoCaptured = 'Photo captured';

  // Preview/Review Screen
  static const String reviewEntry = 'Review Entry';
  static const String reParkingEntryReview = 'Re-Parking Entry Review';
  static const String submitRePark = 'Submit Re-Park';
  static const String retakeButton = 'Retake';
  static const String submittingCarPhoto = 'Submitting car photo...';

  // Image Validation Messages
  static const String vehicleNotFound = 'Vehicle not found in image';
  static const String numberPlateNotFound = 'Vehicle number plate not found';
  static const String errorValidatingImage = 'Error validating image';
  static const String errorProcessingImage = 'Error processing image';

  // Session/Retrieval Related
  static const String badgeNumber = 'Badge Number';
  static const String cardNumber = 'Card Number';
  static const String parkedBy = 'Parked By';
  static const String unknown = 'Unknown';
  static const String retrievalRequest = 'Retrieval Request';
  static const String retrievalRequested = 'Retrieval Requested';
  static const String noActiveRetrievalRequests =
      'No active retrieval requests';
  static const String acceptRequest = 'Okay';
  static const String acceptAllRetrievals = 'Accept all';

  // Handover Related
  static const String confirmHandover = 'Confirm Handover';
  static const String customerMissing = 'Customer Missing';
  static const String confirmationHandover = 'Confirmation Handover';
  static const String enterTwoDigitCode =
      'Enter the 2-digit code provided by the user to complete the handover.';
  static const String customerHasNoPhone = 'Customer has no phone?';

  // Customer Missing Dialog
  static const String reparkConfirmationTitle =
      'Are you sure to re-park the car?';
  static const String reparkConfirmationMessage =
      'This will cancel the retrieval and you must park the car again.';
  static const String proceedToRepark = 'Proceed to Re-Park';
  static const String cancel = 'Cancel';

  // Operator Override (when operator marks Parked/Completed from dashboard)
  static const String transactionCompletedByOperator =
      'Transaction completed by operator. Returning to home.';

  // Arrival Related
  static const String slideToConfirmArrival = 'Confirm Arrival';
  static const String disabledRemainingSeconds = 'Seconds remaining:';
  static const String slideToConfirmHandover = 'Confirm Handover';
  static const String slideToCustomerMissing = 'Customer Missing';
  static const String locateCarUsingPhoto = 'LOCATE CAR USING THE PHOTO';

  // Instruction text above action buttons
  static const String pressBelowToConfirmArrival =
      "Please click the button below once you've entered the lobby.";
  static const String pressBelowToConfirmHandover =
      'Press the button below when the customer has arrived.';
  static const String pressBelowToReportCustomerMissing =
      'If the customer has not arrived within 2 minutes, please press the button below.';

  static const String pressBelowToProceedRepark =
      'Press the button below to proceed to re-park the car.';
  static const String pressBelowToCancel = 'Press below to cancel.';

  // Permission Messages
  static const String locationPermissionRequiredHandover =
      'Location permission is required to confirm handover';
  static const String locationPermissionRequiredArrival =
      'Location permission is required to confirm arrival';

  // Phone Number
  static const String countryCode = '+91';

  // Car Success Screen
  static const String successfullyParked = 'Successfully Parked';
  static const String returnToHome = 'Return To Home';

  // Validation Messages (Manual Entry)
  static const String validationEnterValidTagNumber =
      'Please enter a valid tag number';
  static const String validationEnterTagNumber = 'Please enter the tag number';
  static const String validationEnterValidNumber =
      'Please enter a valid number';
  static const String validationScanCustomerCardOnly =
      'The card you are trying to scan is a valet card. Please scan the customer card.';
  static const String tagSubmissionError =
      'The QR code you scanned or the tag number you entered is invalid or already used. Please kindly check the QR code or tag number.';

  // Dashboard (Operator)
  static const String dashboardOverview = 'Dashboard Overview';
  static const String autoToggleLabel = 'Auto Mode';
  static const String retryButton = 'Retry';
  static const String availableTags = 'Available Tags';
  static const String availableValets = 'Available Valets';
  static const String vehiclesInTransit = 'Vehicles In Transit';
  static const String totalVehiclesParked = 'Total Vehicles Parked';

  // Car Logs Screen (Operator)
  static const String carLogsTitle = 'Car Logs';
  static const String carLogsDescription = 'View vehicle activity logs';
  static const String carLogsKpiTotalParked = 'Total Cars';
  static const String carLogsKpiInTransit = 'Cars In Transit';
  static const String carLogsKpiHandovered = 'Cars Handovered';
  static const String carLogsKpiInLot = 'Parked Cars';
  static const String totalTrips = 'Total Trips';
  static const String totalDistance = 'Total Distance';
  static const String totalTripsValue = '456';
  static const String totalDistanceValue = '2340 km';

  // Car Logs Table Headers
  static const String carLogsTagNumber = 'Card Number';
  static const String carLogsCarStatus = 'Car Status';
  static const String carLogsDuration = 'Duration';
  static const String carLogsParkLocation = 'Park Location';
  static const String carLogsParkedBy = 'Parked By';
  static const String carLogsParkedAt = 'Parked At';
  static const String carLogsRequestedMode = 'Requested Mode';
  static const String carLogsRequestedAt = 'Requested At';
  static const String carLogsHandoveredBy = 'Handovered By';
  static const String carLogsHandoverAt = 'Handover At';

  // Car Logs Search and Messages
  static const String carLogsSearchHint =
      'Search by card number, or parked by...';
  static const String carLogsNoDataMessage = 'No car logs available';
  static const String carLogsErrorMessage = 'Error loading car logs';

  // Car Logs Pagination
  static const String paginationShowLabel = 'Show:';

  /// Shared labels for availability vs offline (slots, valet status, filters).
  static const String availableLabel = 'Available';
  static const String offlineLabel = 'Offline';

  // Drivers Screen (Operator)
  static const String driversTitle = 'Drivers';
  static const String driversDescription = 'Manage and monitor all drivers';
  static const String totalDrivers = 'Total Drivers';
  static const String activeToday = 'Active Today';
  static const String totalDriversValue = '24';
  static const String activeTodayValue = '18';

  // Slots Screen (Operator)
  static const String parkingSlotsTitle = 'Parking Slots';
  static const String parkingSlotsDescription =
      'Manage and monitor parking slots';
  static const String available = availableLabel;
  static const String occupied = 'Occupied';
  static const String availableValue = '12';
  static const String occupiedValue = '8';
  static const String parkedCarTitle = 'Parked Car';
  static const String parkedCarDescription = 'Manage and monitor parked cars';
  static const String noCarsParked = 'No Cars Parked';
  static const String driverParkedCarsDescription =
      'View all cars you have parked or been assigned';
  static const String driverOwnParkedCarsSection = 'Parked by Me';
  static const String driverPassedToMeSection = 'Passed to Me';
  static const String parkedCarSingular = 'parked car';
  static const String parkedCarsPlural = 'parked cars';

  // QR Reader
  static const String cameraError = 'Camera error';
  static const String cameraErrorReinitializing =
      'Camera error. Reinitializing...';

  // Operator Home (Legacy)
  static const String operatorHomeTitle = 'Operator Home';
  static const String welcomeOperator = 'Welcome, Operator! (Menu: ';

  // Operator Dashboard Data
  static const String retrievalRequests = 'Retrieval Requests';
  static const String availableDrivers = 'Available Drivers';
  static const String digitalKeyRack = 'Digital Key Rack';
  static const String noPendingRetrievalRequests =
      'No pending retrieval requests';
  static const String noAvailableDrivers = 'No available drivers at the moment';
  static const String noVehiclesInKeyRack = 'No vehicles in key rack';

  // Assign Driver Dialog
  static const String assignDriverTitle = 'Assign Driver';
  static const String selectDriverInstruction =
      'Select a driver to assign this retrieval request';

  /// Shown when break/logout is blocked until parked or retrieval work is passed.
  static const String pendingWorkDetailsTitle = 'Pending Work Details';
  static const String pendingWorkActiveRetrievalsLabel = 'Active retrievals';
  static const String pendingWorkCardNumbersLabel = 'Card numbers';
  static const String pendingWorkAvailableDriversLabel = 'Available drivers';
  static const String pendingWorkSelectDriver = 'Select Driver';

  // Valet Dashboard
  static const String valetDashboardTitle = 'Valet Dashboard';
  static const String valetDashboardDescription =
      'Monitor and manage your valet team';
  static const String totalValets = 'Total Valets';
  static const String onavailableValets = availableLabel;
  static const String onDutyValets = 'On Duty';
  static const String onBreakValets = 'On Break';
  static const String offlineValets = offlineLabel;
  static const String searchByNameOrPhone = 'Search By Name Or Phone...';
  static const String searchByNameOrCardNumber =
      'Search by name or card number';

  // Valet Status Labels
  static const String statusAvailable = availableLabel;
  static const String statusOnDuty = 'On Duty';
  static const String statusOnBreak = 'On Break';
  static const String statusOffline = offlineLabel;
  static const headerOnBreak = 'On Break';
  static const onBreakScreen = 'On Break';
  static const statusLabel = 'Status';
  static const statusOnline = 'Online';
  static const statusValueOnline = 'online';
  static const statusValueOffline = 'offline';

  // Valet Card Labels
  static const String carsPickedUpLabel = 'Cars Picked Up : ';
  static const String carsHandedOverLabel = 'Cars Hand overed : ';
  static const String onBreakDurationLabel = 'On-Break Duration : ';
  static const String clockInAtLabel = 'Clock In : ';
  static const String clockOutAtLabel = 'Clock Out : ';
  static const String lastActivityLabel = 'Last Activity : ';
  static const String minsLabel = ' mins';
  static const String noValetsFound = 'No valets found';

  static const String confirmAssignment = 'Confirm Assignment';
  static const String cancelText = 'Cancel';
  static const String confirm = 'Confirm';
  static const String parkedByLabel = 'Parked By ';
  static const String assignedToLabel = 'Assigned To ';
  static const String cancelAssignmentTitle = 'Cancel assignment?';
  static const String cancelAssignmentMessage =
      'This session will go back to the retrieval queue.';
  static const String cancelAssignmentConfirm = 'Yes, cancel assignment';
  static const String cancelAssignmentSuccess =
      'Assignment cancelled. Session is back in retrieval queue.';
  static const String cancelAssignmentFailed = 'Failed to cancel assignment';
  static const String recommendedBy = 'Recommended - Parked this vehicle';
  static const String recommendedFor = 'Recommended for';
  static String recommendedForCard(int cardNumber) =>
      'Recommended for $cardNumber';

  static const String sessionContinue =
      'Your session is not completed. Please click Continue to proceed.';
  static const String continueLabel = 'Continue';

  // Car Log Details Popup
  static const String carLogDetailsTitle = 'Car Log Details';
  static const String carStatusLabel = 'Car Status';
  static const String cancelButton = 'Cancel';
  static String failedToUpdateStatus(String error) =>
      'Failed to update status: $error';

  static const String noInternetConnection = 'No internet connection';
  static const String noInternetConnectionHint =
      'Check your connection and try again, or move to an area with better signal.';

  // Mandatory Update Dialog
  static const String mandatoryUpdateDialogTitle = 'New version available!';
  static const String mandatoryUpdateDialogSubtitle =
      'Please update to continue using the app.';
  static const String mandatoryUpdateDialogUpdateNow = 'Update Now';
  static const String language = 'Language';
  static const String failedToChangeLanguage =
      'Failed to change language. Please try again.';
  static const String failedToLoadImageText = 'Failed to load image';

  // Permissions Screen
  static const String exitButton = 'Exit';
  static const String openSettings = 'Open settings';
  static const String permissionsRequiredToContinue =
      'Permissions required to continue';
  static const String permissionsDescription =
      'We need the following permissions to verify your device and provide valet services.';
  static const String permissionLocationTitle = 'Location';
  static const String permissionCameraTitle = 'Camera';
  static const String permissionNotificationsTitle = 'Notifications';
  static const String permissionLocationDescription =
      'Permission to use your location for valet pickup and drop-off.';
  static const String permissionCameraDescription =
      'Permission to scan QR codes and capture vehicle photos.';
  static const String permissionNotificationsDescription =
      'Permission to send push notifications for retrieval requests.';
  static const String accountNoPermissionsMessage =
      'Your account does not have the required permissions to access this app.';
  static const String permissionDeniedTapSettings =
      'Denied multiple times. Tap to open Settings.';

  // Version Check
  static const String checkingForUpdates = 'Checking for updates...';

  // Preview / Edit Details
  static const String editDetails = 'Edit details';
  static const String enterParkingLocationHint = 'Enter parking location...';
  static const String enterVehicleNumberHint = 'Enter vehicle number...';
  static const String saveButton = 'Save';
  static const String parkingLocationCannotBeEmpty =
      'Parking location cannot be empty';
  static const String afterVehicleParkedConfirmInstruction =
      'After the vehicle is successfully parked, please press the button below to confirm.';
  static const String okButton = 'OK';

  // Parked Car / Search
  static const String searchByCardNumberHint = 'Search by card number...';
  static String showingResultsFor(String query) =>
      'Showing results for "$query"';
  static String cardNumberWithHash(int cardNumber) => 'Card #$cardNumber';
  static String parkedByWithName(String name) => 'Parked by $name';
  static const String manualRequestButtonLabel = 'Manual Request';
  static const String failedToLoadSlotsData = 'Failed to load slots data';
  static const String creatingManualRetrievalRequest =
      'Creating manual retrieval request...';

  // Call / Contact
  static const String callButton = 'Call';

  // Pagination
  static const String paginationFirst = '<<';
  static const String paginationPrev = '<';
  static const String paginationNext = '>';
  static const String paginationLast = '>>';

  // Scanner home
  static const String scannerTapScanHint =
      'Tap Scan to read the QR code from the valet card';
}
