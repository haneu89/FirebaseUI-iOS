//
//  Copyright (c) 2017 Google Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "FUIAccountSettingsOperationForgotPassword.h"

#import "FUIAccountSettingsOperation_Internal.h"
#import "FUIAuthBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@implementation FUIAccountSettingsOperationForgotPassword

-(void)execute:(BOOL)showDialog {
  [self onForgotPassword];
}

- (void)onForgotPassword {
  __block FUIStaticContentTableViewCell *inputCell =
  [FUIStaticContentTableViewCell cellWithTitle:[FUIAuthStrings email]
                                        value:_delegate.auth.currentUser.email
                                        action:nil
                                          type:FUIStaticContentTableViewCellTypeInput];
  FUIStaticContentTableViewContent *contents =
      [FUIStaticContentTableViewContent
           contentWithSections:@[
                                 [FUIStaticContentTableViewSection sectionWithTitle:nil
                                                                              cells:@[inputCell]],
                                ]];

  UIViewController *controller =
      [[FUIStaticContentTableViewController alloc]
           initWithContents:contents
                  nextTitle:[FUIAuthStrings send]
                 nextAction:^{ [self onPasswordRecovery:inputCell.value]; }
                 headerText:[FUIAuthStrings passwordRecoveryMessage]];
  controller.title = [FUIAuthStrings passwordRecoveryTitle];
  [_delegate pushViewController:controller];
}

- (void)onPasswordRecovery:(NSString *)email {
  if (![[FUIAuthBaseViewController class] isValidEmail:email]) {
    [self showAlertWithMessage:[FUIAuthStrings invalidEmailError]];
    return;
  }

  [_delegate incrementActivity];

  [_delegate.auth sendPasswordResetWithEmail:email
                             completion:^(NSError *_Nullable error) {
     // The dispatch is a workaround for a bug in FirebaseAuth 3.0.2, which doesn't call the
     // completion block on the main queue.
     dispatch_async(dispatch_get_main_queue(), ^{
       [_delegate decrementActivity];

       if (error) {
         [self finishOperationWithError:error];
         return;
       }

       NSString *message =
           [NSString stringWithFormat:[FUIAuthStrings passwordRecoveryEmailSentMessage], email];
       [self showAlertWithMessage:message];
     });
   }];
}

@end

NS_ASSUME_NONNULL_END
