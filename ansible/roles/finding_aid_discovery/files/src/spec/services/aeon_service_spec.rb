# frozen_string_literal: true

require 'rails_helper'

describe AeonService do
  describe '.submit' do
    context 'with a successful request' do
      context 'with a penn affiliates' do
        let(:base_url) { 'https://aeon.library.upenn.edu/aeon/aeon.dll' }
        let(:request_params) do
          { 'SpecialRequest' => '',
            'Notes' => '',
            'auth' => 1,
            'UserReview' => '',
            'AeonForm' => '',
            'WebRequestForm' => '',
            'SubmitButton' => 'Submit',
            'Request' => "0",
            'ItemTitle_0' => '',
            'CallNumber_0' => '',
            'Site_0' => 'KISLAK',
            'SubLocation_0' => 'Manuscripts',
            'Location_0' => 'scmss',
            'ItemVolume_0' => '',
            'ItemIssue_0' => '' }
        end
        let(:aeon_request) do
          aeon_request = instance_double('AeonRequest')
          allow(aeon_request).to receive(:to_param).and_return request_params
          aeon_request
        end
        let(:successful_response_html) do
          <<~HTML
<html lang="en-US">
<head>
<title>Aeon Main Menu</title>
<meta name="viewport" content="width=device-width, initial-scale=1.0, minimum-scale=1.0, maximum-scale=1.0" />
<meta name="apple-mobile-web-app-capable" content="yes" />
<meta name="apple-mobile-web-app-status-bar-style" content="default" />
<link rel="apple-touch-icon" href="iphone-icon.png" />
<link rel="stylesheet" type="text/css" href="css/main.css" media="screen" />
<link rel="stylesheet" type="text/css" href="css/mobile.css" media="only screen and (max-device-width: 480px)" />
<link rel="stylesheet" type="text/css" href="css/print.css" media="print" /> 
<!--[if lte IE 6]>
<link rel="stylesheet" type="text/css" href="css/ie6_or_less.css" />
<![endif]-->

<script src="https://code.jquery.com/jquery-3.5.1.min.js" 
integrity="sha256-9/aliU8dGd2tb6OSsuzixeV4y/faTqgFtohetphbbj0=" 
crossorigin="anonymous"></script>
<script type="text/javascript" src="js/jquery.metadata.js"></script>
<script type="text/javascript" src="js/mobileTables.js"></script>
<script type="text/javascript" src="js/atlasUtility.js"></script>
<link id="" media="print, projection, screen" type="text/css" href="css/tablesorter.css" rel="stylesheet">
<script type="text/javascript" src="js/jquery.tablesorter.min.js"></script>
<script type='text/javascript'>
    $(document).ready(function () {
		$('TD:contains("12/29/1899 7:00:00 PM")').text('');
        if ($(window).width() > 480) {
            $('table.tablesorter').tablesorter({
                /* dateFormat: "uk", //Uncomment to support DD/MM/YYYY formats */
                widgets: ['zebra'],
                widgetZebra: {
                    css: ["row-even", "row-odd"]
                }
            })
        }
    });
</script>

<link href="https://aeon.library.upenn.edu/nonshib/aeon.dll?Action=2&Type=40&Value=109107971101100005351" rel="alternate" type="application/rss+xml" title="Aeon Alerts" />
</head>
<body id="type-b">
    <div id="wrap">
        <!-- Google Tag Manager -->
<noscript><iframe src="//www.googletagmanager.com/ns.html?id=GTM-NW49L7"
height="0" width="0" style="display:none;visibility:hidden"></iframe></noscript>
<script>(function(w,d,s,l,i){w[l]=w[l]||[];w[l].push({'gtm.start':
new Date().getTime(),event:'gtm.js'});var f=d.getElementsByTagName(s)[0],
j=d.createElement(s),dl=l!='dataLayer'?'&l='+l:'';j.async=true;j.src=
'//www.googletagmanager.com/gtm.js?id='+i+dl;f.parentNode.insertBefore(j,f);
})(window,document,'script','dataLayer','GTM-NW49L7');</script>
<!-- End Google Tag Manager -->
<div id="header">   
	<div id="navytop">
        <div id="headerlinks">
            <a href="http://hdl.library.upenn.edu/1017/125516">Special Collections in Franklin</a>
            <a href="http://dla.library.upenn.edu/dla/ead/">Finding Aids</a>
        </div> 
        <div id="title-name"><a href="http://www.library.upenn.edu/"> <img src="https://www.library.upenn.edu/sites/default/files/images/common/spacer.gif" alt="Penn Libraries" style=""></a></div>
	</div>
	<div id="search">
		<form method="post" name="Search" aeon.dll"="" style="padding-bottom: 8px action=">
			<input type="hidden" value="Search" name="AeonForm">
			<input type="hidden" name="SessionID" id="SessionID" value="R123456789A" />
			<label for="SearchCriteria">
				<input type="text" class="f-criteria" name="SearchCriteria" id="SearchCriteria">				
			</label>
			<input type="submit" class="f-submit" value="Search requests" name="SubmitButton">
			<div id="searchType">                
                    <input type="radio" name="SearchType" id="SearchTypeActive" value="Active" checked="" class="f-searchType">    
                    <label for="SearchTypeActive">Active</label>&nbsp;&nbsp;
                    <input type="radio" name="SearchType" id="SearchTypeAll" value="All" class="f-searchType">
                    <label for="SearchTypeAll">All</label>                
			</div>
		</form>
	</div>

</div>
<div id="status"><span class="statusNormal">Transaction(s) 12345 received.</span></div>
        <div id="content-wrap">
            <div id="utility" aria-label="Menu" role="heading">
	<ul id="nav">
		<li class="active"><a href="aeon.dll?SessionID=R123456789A&Action=99">Logoff Test</a></li>
		<li class="active"><a href="aeon.dll?SessionID=R123456789A&Action=10&Form=10">Main Menu</a></li>
		<li class="active"><a href="aeon.dll?SessionID=R123456789A&Action=10&Form=20&Value=NewRequest">New Request</a></li>
		<li class="active"><a href="aeon.dll?SessionID=R123456789A&Action=10&Form=20&Value=NewOrder">New Reprographic Order</a></li>
		<li class="active"><a href="#">Requests</a>
			<ul>
				<li class="first"><a href="aeon.dll?SessionID=R123456789A&Action=10&Form=76">Saved Requests</a></li>
				<li><a href="aeon.dll?SessionID=R123456789A&Action=10&Form=62">Outstanding Requests</a></li>
				<li><a href="aeon.dll?SessionID=R123456789A&Action=10&Form=70">Cancelled Requests</a></li>
				<li><a href="aeon.dll?SessionID=R123456789A&Action=10&Form=68">History Requests</a></li>
				<li><a href="aeon.dll?SessionID=R123456789A&Action=10&Form=60">All Requests</a></li>		
				<li><a href="aeon.dll?SessionID=R123456789A&Action=10&Form=73">View Notifications</a></li>				
			</ul>
		</li>
		<li class="active"><a href="#">Orders</a>
			<ul>
				<li><a href="aeon.dll?SessionID=R123456789A&Action=10&Form=78">Order Invoices</a></li>
				<li><a href="aeon.dll?SessionID=R123456789A&Action=10&Form=64">Delivered Items</a></li>				
			</ul>
		</li>
		<li class="active"><a href="#">Activities</a>
			<ul>
				<li class="first"><a href="aeon.dll?SessionID=R123456789A&Action=10&Form=90">Activities</a></li>
			</ul>
		</li>
		<li class="active"><a href="#">Preferences</a>
			<ul>
				<li class="first"><a href="aeon.dll?SessionID=R123456789A&Action=10&Form=81">Change User Information</a></li>
			</ul>
		</li>
		<li class="active"><a href="aeon.dll?SessionID=R123456789A&Action=10&Form=1">About University of Pennsylvania Special Collections</a></li>
	</ul>
</div>
            <div id="content" role="heading" aria-label="Content">

				<a href="https://aeon.library.upenn.edu/nonshib/aeon.dll?Action=2&Type=40&Value=109107971101100005351">Subscribe to Alerts Feed</a><br />
                <div id="noAlert" class="alertNone">
<h4>No Alerts</h4>
</div>	

				<div class="default-table">			
					
				</div><br />				

				<div class="researcher-tag-cloud"></div>				
                <div class="default-table" id="table-main-outstanding-requests">
                    <script type="text/javascript">function openRequest(id, event) { 	if (event.button == 0 && !(event.target.href || (event.target.type == "checkbox")) && !(event.ctrlKey || event.shiftKey || event.altKey)) 	{ 		window.location.href = "aeon.dll?SessionID=R123456789A&Action=10&Form=72&value=" + id;		if (event.preventDefault) 			event.preventDefault(); 		else 			event.returnValue = false; 	} } </script>
<table cellspacing="0" width="100%" class="tablesorter" >
<caption>Outstanding Requests
<div class="table-export-link"><a href="aeon.dll?SessionID=R123456789A&Action=10&Form=122&Value=ViewOutstandingRequests">
Export this List
</a></div>
</caption>
<thead>
<tr class="row-headings">
<th>TN</th>
<th>Library</th>
<th>Call&nbsp;Number</th>
<th>Title</th>
<th>Author</th>
<th>Volume/Box</th>
<th>Retrieval Date</th>
<th>Status</th>
<th>Order&nbsp;Status</th>
</tr>
</thead>
<tbody>
<tr class="row-even"  onClick="openRequest(85073, event);">
<td>
<a href="aeon.dll?SessionID=R123456789A&Action=10&Form=63&Value=85073">85073</a>
</td>
<td>
KISLAK
</td>
<td>
Ms. Coll. 1375
</td>
<td>
&nbsp;
</td>
<td>
&nbsp;
</td>
<td>
Box 1
</td>
<td>
&nbsp;
</td>
<td>
Awaiting User Review
</td>
<td>
&nbsp;
</td>
</tr>
</tbody>
</table>
                </div>
                <div id="footer">
     <div>&copy; 2021 <a href="http://www.atlas-sys.com">Atlas Systems, Inc.</a> All Rights Reserved. &#160;|&#160 <a href="tel:+12158987088" class="patronlink">215-898-7088</a> &#160;|&#160; <a href="mailto:rbml@pobox.upenn.edu" class="patronlink"> rbml@pobox.upenn.edu</a></div>
     <div><span  class="hours">Hours:</span>  &#160;<a href="http://events.library.upenn.edu/cgi-bin/calendar.cgi?size=large&mode=&library=reading" class="patronlink" target="_blank">Kislak</a>  &#160;|&#160;  <a href="http://events.library.upenn.edu/cgi-bin/calendar.cgi?size=large&mode=&library=finearts" class="patronlink" target="_blank">Fisher</a>  &#160;|&#160;  <a href="http://events.library.upenn.edu/cgi-bin/calendar.cgi?size=large&mode=&library=lcjs" class="patronlink" target="_blank">Katz CAJS</a></div>
</div>
            </div>
        </div>
    </div>
</body>
</html>
        HTML
end
        before do
          stub_request(:post, base_url).with(body: request_params)
                                       .to_return(status: 200, body: successful_response_html)
        end
        it 'works' do
          response = described_class.submit request: aeon_request, auth_type: :penn
          expect(response.success?).to be true
          expect(response.txnumber).to eq '12345'
        end
      end
    end
  end
end
