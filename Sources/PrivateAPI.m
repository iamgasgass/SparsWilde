//
//  PrivateAPI.m
//  Gass SparsWilde
//
//  Created by Duy Tran on 12/12/25.
//

#import "Gass SparsWilde-Bridging-Header.h"

LSApplicationWorkspace *LSApplicationWorkspaceDefaultWorkspace(void) {
   return [NSClassFromString(@"LSApplicationWorkspace") defaultWorkspace];
}
