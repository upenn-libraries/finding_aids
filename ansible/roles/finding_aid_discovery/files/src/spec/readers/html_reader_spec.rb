require 'rails_helper'

describe HtmlReader do
  let(:html) do
    <<-HTML
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2 Final//EN">
<html>
 <head>
  <title>Index of /paarp</title>
 </head>
 <body>
<h1>Index of /paarp</h1>
  <table>
   <tr><th valign="top"><img src="/icons/blank.gif" alt="[ICO]"></th><th><a href="?C=N;O=D">Name</a></th><th><a href="?C=M;O=A">Last modified</a></th><th><a href="?C=S;O=A">Size</a></th><th><a href="?C=D;O=A">Description</a></th></tr>
   <tr><th colspan="5"><hr></th></tr>
<tr><td valign="top"><img src="/icons/back.gif" alt="[PARENTDIR]"></td><td><a href="/">Parent Directory</a>       </td><td>&nbsp;</td><td align="right">  - </td><td>&nbsp;</td></tr>
<tr><td valign="top"><img src="/icons/text.gif" alt="[TXT]"></td><td><a href="OM_D767.xml">OM_D767.xml</a>            </td><td align="right">2021-11-23 16:11  </td><td align="right"> 27K</td><td>&nbsp;</td></tr>
<tr><td valign="top"><img src="/icons/text.gif" alt="[TXT]"></td><td><a href="OM_E467_S53.xml">OM_E467_S53.xml</a>        </td><td align="right">2021-11-23 16:11  </td><td align="right"> 80K</td><td>&nbsp;</td></tr>
<tr><td valign="top"><img src="/icons/text.gif" alt="[TXT]"></td><td><a href="OM_LMOR.xml">OM_LMOR.xml</a>            </td><td align="right">2021-11-23 16:11  </td><td align="right">191K</td><td>&nbsp;</td></tr>
<tr><td valign="top"><img src="/icons/text.gif" alt="[TXT]"></td><td><a href="OM_PN2277.xml">OM_PN2277.xml</a>          </td><td align="right">2021-11-23 16:11  </td><td align="right"> 40K</td><td>&nbsp;</td></tr>
<tr><td valign="top"><img src="/icons/text.gif" alt="[TXT]"></td><td><a href="PS2043__A44.xml">PS2043__A44.xml</a>        </td><td align="right">2021-11-23 16:11  </td><td align="right"> 20K</td><td>&nbsp;</td></tr>
<tr><td valign="top"><img src="/icons/text.gif" alt="[TXT]"></td><td><a href="VUA_2_9.xml">VUA_2_9.xml</a>            </td><td align="right">2021-11-23 16:11  </td><td align="right">5.4K</td><td>&nbsp;</td></tr>
<tr><td valign="top"><img src="/icons/text.gif" alt="[TXT]"></td><td><a href="VUA_2_10.xml">VUA_2_10.xml</a>           </td><td align="right">2021-11-23 16:11  </td><td align="right">5.7K</td><td>&nbsp;</td></tr>
<tr><td valign="top"><img src="/icons/text.gif" alt="[TXT]"></td><td><a href="VUA_2_11.xml">VUA_2_11.xml</a>           </td><td align="right">2021-11-23 16:11  </td><td align="right">6.5K</td><td>&nbsp;</td></tr>
<tr><td valign="top"><img src="/icons/text.gif" alt="[TXT]"></td><td><a href="VUA_2_14.xml">VUA_2_14.xml</a>           </td><td align="right">2021-11-23 16:11  </td><td align="right">5.4K</td><td>&nbsp;</td></tr>
<tr><td valign="top"><img src="/icons/text.gif" alt="[TXT]"></td><td><a href="VUA_2_16.xml">VUA_2_16.xml</a>           </td><td align="right">2021-11-23 16:11  </td><td align="right">5.2K</td><td>&nbsp;</td></tr>
<tr><td valign="top"><img src="/icons/text.gif" alt="[TXT]"></td><td><a href="VUA_2_17.xml">VUA_2_17.xml</a>           </td><td align="right">2021-11-23 16:11  </td><td align="right">6.6K</td><td>&nbsp;</td></tr>
<tr><td valign="top"><img src="/icons/text.gif" alt="[TXT]"></td><td><a href="VUA_2_18.xml">VUA_2_18.xml</a>           </td><td align="right">2021-11-23 16:11  </td><td align="right">5.2K</td><td>&nbsp;</td></tr>
<tr><td valign="top"><img src="/icons/text.gif" alt="[TXT]"></td><td><a href="VUA_2_19.xml">VUA_2_19.xml</a>           </td><td align="right">2021-11-23 16:11  </td><td align="right">5.8K</td><td>&nbsp;</td></tr>
<tr><td valign="top"><img src="/icons/text.gif" alt="[TXT]"></td><td><a href="VUA_2_20.xml">VUA_2_20.xml</a>           </td><td align="right">2021-11-23 16:11  </td><td align="right">8.8K</td><td>&nbsp;</td></tr>
<tr><td valign="top"><img src="/icons/text.gif" alt="[TXT]"></td><td><a href="VUA_2_22.xml">VUA_2_22.xml</a>           </td><td align="right">2021-11-23 16:11  </td><td align="right">7.4K</td><td>&nbsp;</td></tr>
<tr><td valign="top"><img src="/icons/text.gif" alt="[TXT]"></td><td><a href="VUA_2_23.xml">VUA_2_23.xml</a>           </td><td align="right">2021-11-23 16:11  </td><td align="right"> 81K</td><td>&nbsp;</td></tr>
<tr><td valign="top"><img src="/icons/text.gif" alt="[TXT]"></td><td><a href="VUA_2_25.xml">VUA_2_25.xml</a>           </td><td align="right">2021-11-23 16:11  </td><td align="right"> 12K</td><td>&nbsp;</td></tr>
<tr><td valign="top"><img src="/icons/text.gif" alt="[TXT]"></td><td><a href="VUA_2_26.xml">VUA_2_26.xml</a>           </td><td align="right">2021-11-23 16:11  </td><td align="right"> 20K</td><td>&nbsp;</td></tr>
<tr><td valign="top"><img src="/icons/text.gif" alt="[TXT]"></td><td><a href="VUA_2_27.xml">VUA_2_27.xml</a>           </td><td align="right">2021-11-23 16:11  </td><td align="right"> 12K</td><td>&nbsp;</td></tr>
<tr><td valign="top"><img src="/icons/text.gif" alt="[TXT]"></td><td><a href="VUA_2_28.xml">VUA_2_28.xml</a>           </td><td align="right">2021-11-23 16:11  </td><td align="right"> 29K</td><td>&nbsp;</td></tr>
<tr><td valign="top"><img src="/icons/text.gif" alt="[TXT]"></td><td><a href="VUA_2_29.xml">VUA_2_29.xml</a>           </td><td align="right">2021-11-23 16:11  </td><td align="right"> 27K</td><td>&nbsp;</td></tr>
<tr><td valign="top"><img src="/icons/text.gif" alt="[TXT]"></td><td><a href="VUA_2_30.xml">VUA_2_30.xml</a>           </td><td align="right">2021-11-23 16:11  </td><td align="right">261K</td><td>&nbsp;</td></tr>
<tr><td valign="top"><img src="/icons/text.gif" alt="[TXT]"></td><td><a href="VUA_19.xml">VUA_19.xml</a>             </td><td align="right">2021-11-23 16:11  </td><td align="right"> 17K</td><td>&nbsp;</td></tr>
<tr><td valign="top"><img src="/icons/text.gif" alt="[TXT]"></td><td><a href="VUA_27.xml">VUA_27.xml</a>             </td><td align="right">2021-11-23 16:11  </td><td align="right">6.6K</td><td>&nbsp;</td></tr>
<tr><td valign="top"><img src="/icons/text.gif" alt="[TXT]"></td><td><a href="VUA_28.xml">VUA_28.xml</a>             </td><td align="right">2021-11-23 16:11  </td><td align="right">6.5K</td><td>&nbsp;</td></tr>
<tr><td valign="top"><img src="/icons/text.gif" alt="[TXT]"></td><td><a href="VUA_33.xml">VUA_33.xml</a>             </td><td align="right">2021-11-23 16:11  </td><td align="right"> 23K</td><td>&nbsp;</td></tr>
<tr><td valign="top"><img src="/icons/text.gif" alt="[TXT]"></td><td><a href="VUA_44.xml">VUA_44.xml</a>             </td><td align="right">2021-11-23 16:11  </td><td align="right"> 23K</td><td>&nbsp;</td></tr>
<tr><td valign="top"><img src="/icons/text.gif" alt="[TXT]"></td><td><a href="XM.xml">XM.xml</a>                 </td><td align="right">2021-11-23 16:11  </td><td align="right"> 65K</td><td>&nbsp;</td></tr>
   <tr><th colspan="5"><hr></th></tr>
</table>
</body></html>
HTML
  end

  it 'works' do
    reader = HtmlReader.new(html)
    files = reader.files
    pp files
    pp files.first
    expect(reader.files).to be_an_instance_of Array
    expect(reader.files.first).not_be nil
  end
end
