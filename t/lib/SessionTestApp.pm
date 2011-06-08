#!/usr/bin/env perl

package SessionTestApp;
use Catalyst qw/Session Session::Store::Dummy Session::State::Cookie/;

use strict;
use warnings;

__PACKAGE__->config('Plugin::Session' => {
    # needed for live_verify_user_agent.t; should be harmless for other tests 
    verify_user_agent => 1,  
    
    # need for live_verify_address.t; should be harmless for other tests
    verify_address => 1,

});

__PACKAGE__->setup;

__PACKAGE__;

