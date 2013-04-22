#!/usr/bin/perl 

use strict;
use warnings;

use LWP::UserAgent;
use HTTP::Request;
use HTTP::Headers;
use Getopt::Long;
use Data::Dumper;
use XML::Simple;
use DBI;

package SMS;

#
# Params
#
my $apiUrl       = 'http://192.168.1.1/api';
my $smsMaxLength = 140;

#
# List sms in the dongle
#
sub telephonySmsList {

    my $params       = shift;
    my $resultmsg    = '';
    my $resultstatus = '100';

    my $Result = { status => $resultstatus, message => $resultmsg };

    my $req = '
                <?xml version="1.0" encoding="UTF-8"?>
                        <request>
                                <PageIndex>1</PageIndex>
                                <ReadCount>20</ReadCount>
                                <BoxType>1</BoxType>
                                <SortType>0</SortType>
                                <Ascending>0</Ascending>
                                <UnreadPreferred>1</UnreadPreferred>
                        </request>';

    return apiRequest(
        { reqUrl => '/sms/sms-list', reqType => 'POST', req => $req } );
}

#
# Delete SMS bu id (id you could find in telephonySmsList)
#
sub telephonySmsDelete {
    my $params = shift;
    my $Index  = $params->{'index'};

    my $resultmsg    = '';
    my $resultstatus = '100';

    my $Result = { status => $resultstatus, message => $resultmsg };

    if ( !$Index or $Index !~ /\d+/ ) {
        $Result->{'status'}  = "201";
        $Result->{'message'} = 'Index value must be a number !';
        return $Result;
    }

    my $req = '<?xml version="1.0" encoding="UTF-8"?>
        <request>
            <Index>' . $Index . '</Index>
		</request>';

    return apiRequest(
        { reqUrl => '/sms/delete-sms', reqType => 'POST', req => $req } );
}

#
# Send a sms
#
sub telephonySmsSend {
    my $params = shift;

    my $To      = $params->{'to'};
    my $Message = $params->{'message'};

    my $resultmsg    = '';
    my $resultstatus = '100';

    my $Result = { status => $resultstatus, message => $resultmsg };

    # Test number (allow only mobile numbers in France)
    if ( $To !~ /^(0033|0){1}[67]{1}\d{8}$/ ) {
        $Result->{'status'} = "201";
        $Result->{'message'} =
          'Destination number must be a mobile phone in France !';
        return $Result;
    }

    # Test message
    if ( not defined $Message ) {
        $Result->{'message'} = "Error : No message defined ! ";
        $Result->{'status'}  = "201";
        return $Result;
    }

    # Test message length
    if ( length($Message) > $smsMaxLength ) {
        $Result->{'message'} = "Error : Message is too long ! ";
        $Result->{'status'}  = "201";
        return $Result;
    }

    # Prepare request
    my $req = '<?xml version="1.0" encoding="UTF-8"?>
            <request>
                <Index>-1</Index>
                <Phones>
                    <Phone>' . $To . '</Phone>
                </Phones>
                <Sca></Sca>
                <Content>' . $Message . '</Content>
                <Length>' . length($Message) . '</Length>
                <Reserved>1</Reserved>
                <Date>' . `date "+%Y-%m-%d %H:%M:%S"` . '</Date>
            </request>';

    # Make rquest
    return apiRequest(
        { reqUrl => '/sms/send-sms', reqType => 'POST', req => $req } );
}

#
# Remove all sms from the dongle memory
#
sub telephonySmsClean {
    my $req = '
		<?xml version="1.0" encoding="UTF-8"?>
			<request>
				<PageIndex>1</PageIndex>
				<ReadCount>20</ReadCount>
				<BoxType>2</BoxType>
				<SortType>0</SortType>
				<Ascending>0</Ascending>
				<UnreadPreferred>0</UnreadPreferred>
			</request>
	';

    my $fnret = apiRequest(
        {
            req     => $req,
            reqUrl  => '/sms/sms-list',
            reqType => 'POST',
        }
    );

    my $xml = XML::Simple::XMLin( $fnret->{'value'}, ForceArray => 1 );

    my $Messages = $xml->{'Messages'}[0]->{'Message'};
    foreach my $Sms ( @{$Messages} ) {
        my $fnret = telephonySmsDelete( { index => $Sms->{'Index'}[0] } );
    }
}

#
# Function that make the call to the dongle api
#
sub apiRequest {
    my $params = shift;

    my $reqUrl  = $params->{'reqUrl'};
    my $reqType = $params->{'reqType'} || 'POST';
    my $req     = $params->{'req'} || undef;

    my $Result = { status => 100, message => '', value => '' };

    if ( not defined $reqUrl ) {
        $Result->{'message'} = 'Specify a request url !';
        $Result->{'status'}  = '201';
        return $Result;
    }

    my $objHeader = HTTP::Headers->new;
    $objHeader->push_header( 'Content-Type' => 'text/xml' );

    my $objRequest =
      HTTP::Request->new( $reqType, $apiUrl . $reqUrl, $objHeader, $req );

    my $objUserAgent = LWP::UserAgent->new;
    my $objResponse  = $objUserAgent->request($objRequest);

    $Result->{'value'} = $objResponse->decoded_content;

    if ( not $objResponse->is_success ) {
        $Result->{'status'} = '500';
    }

    return $Result;
}
