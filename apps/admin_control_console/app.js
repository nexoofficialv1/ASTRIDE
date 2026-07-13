const state={api:localStorage.apiBase||'http://localhost:3333',token:localStorage.adminToken||'',lang:localStorage.adminLang||'en',page:'dashboard',cache:{},dispatchTimer:null,dispatchMap:null};
const $=s=>document.querySelector(s),$$=s=>[...document.querySelectorAll(s)];
const text={
en:{dashboard:'Dashboard',rides:'Live Rides',drivers:'Drivers',payments:'Payments',settlements:'Settlements',safety:'Safety & SOS',complaints:'Complaints',notifications:'Notifications',providers:'Provider Configuration',settings:'Service Controls',audit:'Audit & Storage',controlCenter:'Operations Control Center',internalOnly:'Secure internal administration only',apiBase:'API base URL',username:'Username',password:'Password',signIn:'Sign in',productionWarning:'Use production credentials. Demo passwords are not accepted in production mode.',internalMonitoring:'Internal monitoring',refresh:'Refresh',logout:'Logout',save:'Save changes',test:'Test provider',reconcile:'Reconcile payments',fareManagement:'Fare Management',dynamicPricing:'Dynamic Pricing',nightService:'Night Service',zoneManager:'Zone Manager',promoterManagement:'Promoter Management',compensation:'Compensation Center',saferideAdmin:'SafeRide',partnerSettlements:'Partner Settlements',businessOperations:'Business Operations',campaigns:'Offers & Campaigns',referrals:'Refer & Earn'},
bn:{dashboard:'ড্যাশবোর্ড',rides:'চলমান যাত্রা',drivers:'চালক',payments:'পেমেন্ট',settlements:'সেটেলমেন্ট',safety:'নিরাপত্তা ও SOS',complaints:'অভিযোগ',notifications:'নোটিফিকেশন',providers:'প্রোভাইডার কনফিগারেশন',settings:'সার্ভিস কন্ট্রোল',audit:'অডিট ও স্টোরেজ',controlCenter:'অপারেশন কন্ট্রোল সেন্টার',internalOnly:'শুধু নিরাপদ অভ্যন্তরীণ প্রশাসনের জন্য',apiBase:'API বেস URL',username:'ইউজারনেম',password:'পাসওয়ার্ড',signIn:'সাইন ইন',productionWarning:'প্রোডাকশন ক্রেডেনশিয়াল ব্যবহার করুন। প্রোডাকশনে ডেমো পাসওয়ার্ড গ্রহণ করা হবে না।',internalMonitoring:'অভ্যন্তরীণ মনিটরিং',refresh:'রিফ্রেশ',logout:'লগআউট',save:'পরিবর্তন সংরক্ষণ',test:'প্রোভাইডার পরীক্ষা',reconcile:'পেমেন্ট মিলিয়ে দেখুন',fareManagement:'ভাড়া ব্যবস্থাপনা',dynamicPricing:'ডায়নামিক প্রাইসিং',nightService:'নাইট সার্ভিস',zoneManager:'জোন ম্যানেজার',promoterManagement:'প্রোমোটার ব্যবস্থাপনা',compensation:'কম্পেনসেশন সেন্টার',saferideAdmin:'সেফরাইড',partnerSettlements:'পার্টনার সেটেলমেন্ট',businessOperations:'ব্যবসায়িক নিয়ন্ত্রণ',campaigns:'অফার ও ক্যাম্পেইন',referrals:'রেফার অ্যান্ড আর্ন'},
hi:{dashboard:'डैशबोर्ड',rides:'लाइव यात्राएँ',drivers:'ड्राइवर',payments:'भुगतान',settlements:'सेटलमेंट',safety:'सुरक्षा और SOS',complaints:'शिकायतें',notifications:'नोटिफिकेशन',providers:'प्रोवाइडर कॉन्फ़िगरेशन',settings:'सेवा नियंत्रण',audit:'ऑडिट और स्टोरेज',controlCenter:'ऑपरेशन कंट्रोल सेंटर',internalOnly:'केवल सुरक्षित आंतरिक प्रशासन के लिए',apiBase:'API बेस URL',username:'यूज़रनेम',password:'पासवर्ड',signIn:'साइन इन',productionWarning:'प्रोडक्शन क्रेडेंशियल उपयोग करें। प्रोडक्शन में डेमो पासवर्ड स्वीकार नहीं होंगे।',internalMonitoring:'आंतरिक निगरानी',refresh:'रिफ्रेश',logout:'लॉगआउट',save:'परिवर्तन सहेजें',test:'प्रोवाइडर जाँचें',reconcile:'भुगतान मिलान करें',fareManagement:'किराया प्रबंधन',dynamicPricing:'डायनेमिक प्राइसिंग',nightService:'नाइट सर्विस',zoneManager:'ज़ोन मैनेजर',promoterManagement:'प्रमोटर प्रबंधन',compensation:'मुआवज़ा केंद्र',saferideAdmin:'सेफराइड',partnerSettlements:'पार्टनर सेटलमेंट',businessOperations:'व्यावसायिक नियंत्रण',campaigns:'ऑफर और अभियान',referrals:'रेफर एंड अर्न'}};
const pages=['dashboard','rides','drivers','fareManagement','dynamicPricing','nightService','zoneManager','campaigns','referrals','promoterManagement','compensation','saferideAdmin','partnerSettlements','payments','settlements','safety','complaints','notifications','providers','settings','audit'];
const tr=k=>text[state.lang]?.[k]||text.en[k]||k;
const esc=v=>String(v??'').replace(/[&<>'"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;',"'":'&#39;','"':'&quot;'}[c]));
function toast(msg){const el=$('#toast');el.textContent=msg;el.hidden=false;clearTimeout(toast.t);toast.t=setTimeout(()=>el.hidden=true,2400)}
async function api(path,options={}){const headers={'content-type':'application/json',authorization:`Bearer ${state.token}`,...(options.headers||{})};const r=await fetch(state.api+path,{...options,headers});let body={};try{body=await r.json()}catch{}if(r.status===401){logout();throw Error('Session expired')}if(!r.ok)throw Error(body.message||body.error||`HTTP ${r.status}`);return body}
async function ensureLeaflet(){
  if(window.L)return window.L;
  if(!document.querySelector('link[data-leaflet]')){
    const link=document.createElement('link');
    link.rel='stylesheet';
    link.href='https://unpkg.com/leaflet@1.9.4/dist/leaflet.css';
    link.dataset.leaflet='1';
    document.head.appendChild(link);
  }
  await new Promise((resolve,reject)=>{
    const existing=document.querySelector('script[data-leaflet]');
    if(existing){
      if(window.L)return resolve();
      existing.addEventListener('load',resolve,{once:true});
      existing.addEventListener('error',reject,{once:true});
      return;
    }
    const script=document.createElement('script');
    script.src='https://unpkg.com/leaflet@1.9.4/dist/leaflet.js';
    script.dataset.leaflet='1';
    script.onload=resolve;
    script.onerror=reject;
    document.head.appendChild(script);
  });
  return window.L;
}
const pointOk=p=>p&&Number.isFinite(Number(p.lat))&&Number.isFinite(Number(p.lng));
async function drawDispatchMap(data){
  const target=$('#dispatchMap');
  if(!target)return;
  try{
    const L=await ensureLeaflet();
    if(state.dispatchMap){
      state.dispatchMap.remove();
      state.dispatchMap=null;
    }
    const pickup=data.booking?.pickup;
    const destination=data.booking?.destination;
    const center=pointOk(pickup)
      ?[Number(pickup.lat),Number(pickup.lng)]
      :[23.2196,88.3628];
    const map=L.map(target).setView(center,14);
    state.dispatchMap=map;
    L.tileLayer(
      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
      {maxZoom:19,attribution:'© OpenStreetMap contributors'},
    ).addTo(map);
    const bounds=[];
    if(pointOk(pickup)){
      const p=[Number(pickup.lat),Number(pickup.lng)];
      bounds.push(p);
      L.marker(p).addTo(map).bindPopup(
        `<b>Passenger pickup</b><br>${esc(data.booking.pickupAddress||data.booking.passengerId||'Searching passenger')}`,
      );
    }
    if(pointOk(destination)){
      const p=[Number(destination.lat),Number(destination.lng)];
      bounds.push(p);
      L.circleMarker(p,{radius:9,color:'#f97316',fillOpacity:.9})
        .addTo(map)
        .bindPopup(`<b>Destination</b><br>${esc(data.booking.destinationAddress||'Pinned destination')}`);
    }
    for(const driver of data.candidates||[]){
      if(!pointOk(driver.location))continue;
      const p=[Number(driver.location.lat),Number(driver.location.lng)];
      bounds.push(p);
      L.circleMarker(p,{radius:9,color:'#16a34a',fillOpacity:.9})
        .addTo(map)
        .bindPopup(
          `<b>${esc(driver.fullName||driver.id)}</b><br>`+
          `${esc(driver.vehicle?.number||'Vehicle number unavailable')}<br>`+
          `${esc(driver.distanceToPickupKm)} km from pickup`,
        );
    }
    if(pointOk(data.assignedDriver?.location)){
      const p=[
        Number(data.assignedDriver.location.lat),
        Number(data.assignedDriver.location.lng),
      ];
      bounds.push(p);
      L.circleMarker(p,{radius:11,color:'#1d4ed8',fillOpacity:1})
        .addTo(map)
        .bindPopup(`<b>Assigned Driver</b><br>${esc(data.assignedDriver.fullName||data.assignedDriver.id)}`);
    }
    if(bounds.length>1)map.fitBounds(bounds,{padding:[30,30]});
    setTimeout(()=>map.invalidateSize(),120);
  }catch(error){
    target.innerHTML=`<div class="map-fallback"><b>Map could not load.</b><br>Pickup: ${esc(JSON.stringify(data.booking?.pickup||{}))}<br>Nearby eligible drivers: ${esc((data.candidates||[]).length)}</div>`;
  }
}
function dispatchPanel(data){
  const booking=data.booking||{};
  const candidates=data.candidates||[];
  const allowed=booking.status==='SEARCHING';
  const events=(data.events||[]).slice(-5).reverse();
  return `<div class="panel-header">
    <div><h3>Live Dispatch Map</h3><p class="muted"><span class="mono">${esc(booking.id)}</span> · ${badge(booking.status)}</p></div>
    <button class="secondary" id="closeDispatch">Close</button>
  </div>
  <div class="dispatch-summary">
    <div><small>Pickup</small><b>${esc(booking.pickupAddress||JSON.stringify(booking.pickup||{}))}</b></div>
    <div><small>Destination</small><b>${esc(booking.destinationAddress||JSON.stringify(booking.destination||{}))}</b></div>
    <div><small>Search radius</small><b>${esc(data.searchRadiusKm||0)} km</b></div>
    <div><small>Eligible free drivers</small><b>${esc(candidates.length)}</b></div>
  </div>
  <div id="dispatchMap" class="dispatch-map"></div>
  ${data.assignedDriver?`<div class="assigned-driver-strip"><b>Assigned:</b> ${esc(data.assignedDriver.fullName||data.assignedDriver.id)} · ${esc(data.assignedDriver.vehicle?.number||'-')}</div>`:''}
  <div class="panel-header"><h3>Nearby eligible drivers</h3>${allowed&&candidates.length?`<button class="primary" id="autoAssignNearest">Auto assign nearest</button>`:''}</div>
  ${candidates.length?table(candidates,[
    ['Driver',x=>`<b>${esc(x.fullName||x.id)}</b><div class="mono muted">${esc(x.id)}</div>`],
    ['Vehicle',x=>esc(x.vehicle?.number||'-')],
    ['Distance',x=>`${esc(x.distanceToPickupKm)} km`],
    ['Rating',x=>esc(x.rating||5)],
    ['Action',x=>allowed?`<button class="secondary manual-assign-driver" data-driver="${esc(x.id)}">Assign</button>`:'-'],
  ]):'<div class="empty">No eligible free verified Driver is currently inside the search radius.</div>'}
  ${booking.driverCancellationHistory?.length?`<div class="danger-strip"><b>Driver cancellations:</b> ${booking.driverCancellationHistory.map(x=>`${esc(x.driverId)} — ${esc(x.reason)}`).join('<br>')}</div>`:''}
  <div class="audit-mini"><h4>Latest ride events</h4>${events.map(x=>`<div><span>${esc(x.eventType)}</span><small>${esc(x.createdAt)}</small></div>`).join('')||'<p class="muted">No events</p>'}</div>`;
}
function badge(v){const s=String(v??'UNKNOWN'),c=/CAPTURED|COMPLETED|APPROVED|ONLINE|RESOLVED|DELIVERED|CASH_COLLECTED/i.test(s)?'good':/FAILED|REJECTED|SUSPENDED|OPEN|SOS|BLOCKED/i.test(s)?'bad':'warn';return `<span class="status ${c}">${esc(s)}</span>`}
function fileHref(value){
  const url=String(value||'').trim();
  if(!url)return '#';
  if(/^https?:\/\//i.test(url))return url;
  return `${state.api.replace(/\/$/,'')}/${url.replace(/^\//,'')}`;
}
function verificationBadge(summary={}){
  if(summary.readyForApproval)return badge('READY');
  if(Number(summary.rejectedCount||0)>0)return badge('REJECTED');
  if(Number(summary.pendingCount||0)>0)return badge('PENDING');
  if(Number(summary.missingCount||0)>0)return badge('INCOMPLETE');
  return badge('PENDING');
}
function approvalChainBadge(approval={}){
  const promoter=approval.promoter?.status||'PENDING';
  const area=approval.areaPromoter?.status||'PENDING';
  const admin=approval.admin?.status||'PENDING';
  return `<div class="approval-mini"><span>P ${badge(promoter)}</span><span>A ${badge(area)}</span><span>Admin ${badge(admin)}</span></div>`;
}
function driverRows(items,online){
  return table(items,[
    ['Driver',x=>`<b>${esc(x.fullName||x.id)}</b><div class="mono muted">${esc(x.mobile||x.id)}</div>`],
    ['Status',x=>badge(x.status)],
    ['Availability',x=>badge(online.get(x.id)?.online?'ONLINE':'OFFLINE')],
    ['Vehicle',x=>esc(x.vehicleNumber||x.vehicle?.number||'-')],
    ['Promoter',x=>x.assignment?.promoter?`<b>${esc(x.assignment.promoter.name||x.assignment.promoter.id)}</b><div class="mono muted">${esc(x.assignment.promoter.id)}</div>`:badge('UNASSIGNED')],
    ['Documents',x=>`${verificationBadge(x.verification)}<div class="muted compact-note">${esc(x.verification?.approvedCount||0)}/${esc(x.verification?.requiredCount||5)} final-verified</div>`],
    ['Approval chain',x=>approvalChainBadge(x.approval)],
    ['Action',x=>`<button class="secondary review-driver" data-id="${esc(x.id)}">Final review</button>`],
  ]);
}
function renderNav(){$('#nav').innerHTML=pages.map(p=>`<button class="nav-button ${state.page===p?'active':''}" data-page="${p}">${tr(p)}</button>`).join('');$$('[data-page]').forEach(b=>b.onclick=()=>loadPage(b.dataset.page))}
function translateShell(){$$('[data-i18n]').forEach(el=>el.textContent=tr(el.dataset.i18n));renderNav();$('#title').textContent=tr(state.page)}
function table(items,cols){if(!items?.length)return '<div class="empty">No records available</div>';return `<div class="table-wrap"><table><thead><tr>${cols.map(c=>`<th>${esc(c[0])}</th>`).join('')}</tr></thead><tbody>${items.map(x=>`<tr>${cols.map(c=>`<td>${c[1](x)??''}</td>`).join('')}</tr>`).join('')}</tbody></table></div>`}
function showApp(){
  const logged=!!state.token;
  const login=$('#login');
  const app=$('#app');
  login.hidden=logged;
  app.hidden=!logged;
  login.style.display=logged?'none':'grid';
  app.style.display=logged?'block':'';
  $('#apiBase').value=state.api;
  $('#language').value=state.lang;
  if(logged){
    translateShell();
    loadPage(state.page);
  }
}
async function loadPage(page){if(state.dispatchTimer){clearInterval(state.dispatchTimer);state.dispatchTimer=null}if(state.dispatchMap){state.dispatchMap.remove();state.dispatchMap=null}state.page=page;translateShell();const c=$('#content');c.innerHTML='<div class="panel loading">Loading…</div>';try{const fn=views[page];c.innerHTML=await fn();wire(page);$('#connectionBadge').className='badge good';$('#connectionBadge').textContent='API Online'}catch(e){$('#connectionBadge').className='badge bad';$('#connectionBadge').textContent='API Error';c.innerHTML=`<div class="panel danger-strip"><h3>Unable to load</h3><p class="muted">${esc(e.message)}</p><button class="secondary" id="retry">Retry</button></div>`;$('#retry').onclick=()=>loadPage(page)}}
const views={
async dashboard(){const d=await api('/v1/admin/dashboard');const labels={totalBookings:'Total bookings',liveRides:'Live rides',completedRides:'Completed',driversRegistered:'Drivers',driversOnline:'Online drivers',openComplaints:'Open complaints',paymentsCaptured:'Captured payments',pendingSettlements:'Pending settlements',openSos:'Open SOS',openRiskEvents:'Risk events'};return `<div class="cards">${Object.entries(d.cards).map(([k,v])=>`<div class="card"><small>${esc(labels[k]||k)}</small><strong>${esc(v)}</strong></div>`).join('')}</div><div class="grid"><div class="panel"><div class="panel-header"><h3>Operations</h3><small class="muted">${esc(d.generatedAt)}</small></div>${Object.entries(d.operations).map(([k,v])=>`<div class="switch-row"><span>${esc(k)}</span>${badge(v?'ON':'OFF')}</div>`).join('')}</div><div class="panel"><h3>Active providers</h3>${Object.entries(d.providers).map(([k,v])=>`<div class="switch-row"><span>${esc(k)}</span><b>${esc(v.active||'-')} · ${esc(v.mode||'')}</b></div>`).join('')}</div></div>`},
async rides(){
  const d=await api('/v1/admin/rides');
  return `<div class="toolbar">
    <input id="q" placeholder="Search ride / passenger / driver">
    <select id="statusFilter">
      <option value="">All statuses</option>
      ${[...new Set(d.items.map(x=>x.status))].map(x=>`<option>${esc(x)}</option>`).join('')}
    </select>
    <button class="secondary" id="refreshLiveRides">Refresh</button>
  </div>
  <div id="rideDispatchPanel" class="panel dispatch-panel" hidden></div>
  <div id="rideTable">${rideTable(d.items)}</div>`;
},
async drivers(){
  const [d,partnerData]=await Promise.all([api('/v1/admin/drivers'),api('/v1/admin/promoters')]);
  const online=new Map((d.availability||[]).map(x=>[x.driverId||x.id,x]));
  const promoters=(partnerData.items||[]).filter(x=>x.role==='PROMOTER'&&x.status==='ACTIVE');
  const promoterOptions=promoters.map(x=>`<option value="${esc(x.id)}" data-area-promoter="${esc(x.areaPromoterId||'')}">${esc(x.name||x.id)} · ${esc(x.mobile||x.id)}</option>`).join('');
  return `<div class="toolbar"><input id="driverSearch" placeholder="Search driver / mobile / vehicle"><button class="primary" id="addDriver">＋ Add Driver</button></div>
  <div id="driverCreatePanel" class="panel creation-panel" hidden><div class="panel-header"><div><h3>Create Driver Account</h3><p class="muted">Admin must assign every directly-created Driver under an active Promoter. Area Promoter is selected automatically.</p></div><button class="secondary" id="closeDriverForm">Close</button></div>
  <div class="form-grid"><label class="field"><span>Full name *</span><input id="driverFullName"></label><label class="field"><span>Mobile number *</span><input id="driverMobile" inputmode="numeric"></label><label class="field"><span>Driver ID</span><input id="driverLoginId" placeholder="Auto if left blank"></label><label class="field"><span>Temporary password *</span><input id="driverTempPassword" type="password" minlength="8"></label>
  <label class="field full"><span>Assign under Promoter *</span><select id="driverPromoterId" required><option value="">Select an active Promoter</option>${promoterOptions}</select></label><label class="field full"><span>Area Promoter</span><input id="driverAreaPromoterDisplay" value="Auto-selected from Promoter" readonly></label>
  <label class="field"><span>Area ID</span><input id="driverAreaId"></label><label class="field"><span>Primary Zone ID</span><input id="driverZoneId"></label><label class="field"><span>Vehicle number</span><input id="driverVehicleNumber"></label><label class="field"><span>Vehicle type</span><select id="driverVehicleType"><option value="FULL_TOTO">Full Toto</option><option value="SHARE_TOTO">Share Toto</option><option value="MOTORCYCLE">Motorcycle</option></select></label><label class="field"><span>Language</span><select id="driverLanguage"><option value="en">English</option><option value="bn">বাংলা</option><option value="hi">हिंदी</option></select></label></div>
  <div class="actions"><button class="primary" id="createDriverAccount">Create Driver Account</button></div><pre id="driverCreateResult" class="result-box" hidden></pre></div>
  <div id="driverReviewPanel" class="panel verification-panel" hidden></div><div id="driverTable">${driverRows(d.profiles||[],online)}</div>`;
},
async payments(){const [p,w,r]=await Promise.all([api('/v1/admin/payments'),api('/v1/admin/payment-webhooks'),api('/v1/admin/payment-reconciliations')]);return `<div class="toolbar"><button class="primary" id="reconcileAll">${tr('reconcile')}</button><span class="muted">Webhooks: ${w.items.length} · Reconciliations: ${r.items.length}</span></div>${table(p.items,[['Payment',x=>`<span class="mono">${esc(x.id)}</span>`],['Booking',x=>esc(x.bookingId||'-')],['Provider',x=>esc(x.provider)],['Status',x=>badge(x.status)],['Amount',x=>`${esc(x.currency||'INR')} ${((x.amountPaise||0)/100).toFixed(2)}`],['Provider ID',x=>`<span class="mono">${esc(x.providerPaymentId||'-')}</span>`]])}`},
async settlements(){const d=await api('/v1/admin/settlements');return table(d.items,[['Settlement',x=>`<span class="mono">${esc(x.id)}</span>`],['Driver',x=>esc(x.driverId)],['Status',x=>badge(x.status)],['Amount',x=>((x.amountPaise||0)/100).toFixed(2)],['Requested',x=>esc(x.createdAt||x.requestedAt||'-')]])},
async safety(){const [s,r]=await Promise.all([api('/v1/admin/sos'),api('/v1/admin/risk-events')]);return `<div class="grid"><div class="panel danger-strip"><h3>Active SOS</h3>${table(s.items,[['ID',x=>`<span class="mono">${esc(x.id)}</span>`],['Booking',x=>esc(x.bookingId||'-')],['Actor',x=>esc(x.actorType||x.userType||'-')],['Status',x=>badge(x.status)],['Action',x=>x.status==='RESOLVED'?'—':`<button class="secondary resolve-sos" data-id="${esc(x.id)}">Resolve</button>`]])}</div><div class="panel"><h3>Risk events</h3>${table(r.items,[['Type',x=>esc(x.type||x.eventType)],['Booking',x=>esc(x.bookingId||'-')],['Score',x=>esc(x.score??'-')],['Status',x=>badge(x.status)],['Created',x=>esc(x.createdAt||'-')]])}</div></div>`},
async complaints(){const d=await api('/v1/admin/complaints');return table(d.items,[['Category',x=>esc(x.category)],['Booking',x=>esc(x.bookingId||'-')],['Priority',x=>badge(x.priority)],['Status',x=>badge(x.status)],['Description',x=>esc(x.description)],['Action',x=>x.status==='CLOSED'?'—':`<button class="secondary close-complaint" data-id="${esc(x.id)}">Close</button>`]])},
async notifications(){const d=await api('/v1/admin/notifications');return table(d.items,[['Type',x=>esc(x.type)],['Recipient',x=>esc(x.userId||x.deviceToken||'-')],['Status',x=>badge(x.status)],['Title',x=>esc(x.title)],['Provider',x=>esc(x.provider||'-')],['Created',x=>esc(x.createdAt||'-')]])},
async providers(){const [cfg,creds,vault]=await Promise.all([api('/v1/admin/config'),api('/v1/admin/providers/credentials'),api('/v1/admin/providers/vault-status')]);return `<div class="grid"><div class="panel"><h3>Provider selection</h3><div class="form-grid">${providerSelect('maps','Map provider',['mappls','google','osm'],cfg.providers.maps)}${providerSelect('payments','Payment provider',['razorpay','bharatpe','cash'],cfg.providers.payments)}${providerSelect('otp','OTP provider',['mock','2factor','msg91','twilio'],cfg.providers.otp||{})}${providerSelect('notifications','Notification provider',['mock','firebase','onesignal'],cfg.providers.notifications||{})}</div><div class="actions"><button class="primary" id="saveProviders">${tr('save')}</button></div></div><div class="panel"><h3>Encrypted credential vault</h3><p class="muted">Persistent: ${vault.persistent?'YES':'NO'} · entries: ${vault.count}</p>${table(creds.items,[['Type',x=>esc(x.type)],['Provider',x=>esc(x.name)],['Mode',x=>esc(x.mode)],['Configured',x=>badge(x.configured?'YES':'NO')],['Updated',x=>esc(x.updatedAt||'-')]])}</div></div><div class="panel"><h3>Add / replace credentials</h3><div class="form-grid"><label class="field">Type<select id="credentialType"><option>otp</option><option>maps</option><option>payments</option><option>notifications</option></select></label><label class="field">Provider<input id="credentialName" placeholder="msg91 / google / razorpay / firebase"></label><label class="field">Mode<select id="credentialMode"><option>test</option><option>live</option></select></label><label class="field full"><span>Credential JSON</span><textarea id="credentialJson" rows="10" placeholder='{"keyId":"...","keySecret":"..."}'></textarea></label></div><p class="muted">Firebase may include server service-account fields and clients.passenger / clients.driver public FirebaseOptions. Secrets are encrypted before persistent storage.</p><div class="actions"><button class="primary" id="saveCredential">Save encrypted credentials</button><button class="danger" id="deleteCredential">Delete selected credentials</button></div></div><div class="panel"><h3>Test provider</h3><div class="form-grid"><label class="field">Type<select id="testType"><option>otp</option><option>notifications</option><option>payments</option><option>maps</option></select></label><label class="field">Provider<input id="testName" value="mock"></label><label class="field">Mode<select id="testMode"><option>test</option><option>live</option></select></label></div><div class="actions"><button class="secondary" id="testProvider">${tr('test')}</button></div><pre id="testResult" class="mono muted"></pre></div>`},
async settings(){const d=await api('/v1/admin/config');return `<div class="grid"><div class="panel"><h3>Service operations</h3>${Object.entries(d.operations).map(([k,v])=>toggle(k,v)).join('')}<div class="actions"><button class="primary" id="saveOps">${tr('save')}</button></div></div><div class="panel"><h3>Runtime summary</h3><pre class="mono">${esc(JSON.stringify({version:d.version,updatedAt:d.updatedAt,features:d.features},null,2))}</pre></div></div>`},
async audit(){const [a,s]=await Promise.all([api('/v1/admin/audit'),api('/v1/admin/storage/status')]);return `<div class="grid"><div class="panel"><div class="panel-header"><h3>Storage status</h3><button class="secondary" id="flushStorage">Flush now</button></div><pre class="mono">${esc(JSON.stringify(s,null,2))}</pre></div><div class="panel"><h3>Recent audit log</h3>${table(a.items.slice(0,100),[['Action',x=>esc(x.action)],['Admin',x=>esc(x.adminUserId||x.actorId||'-')],['Created',x=>esc(x.createdAt||'-')],['Details',x=>`<span class="mono">${esc(JSON.stringify(x.details||x.payload||{}))}</span>`]])}</div></div>`},
async fareManagement(){const c=await api('/v1/admin/config');const r=c.businessRules.rideTypes;return `<div class="panel"><div class="panel-header"><div><h3>Fare & Commission Rules</h3><p class="muted">All values are remotely configurable; no app update is required.</p></div><button class="primary" id="saveFareRules">${tr('save')}</button></div><div class="fare-grid">${Object.entries(r).map(([type,v])=>`<section class="rule-card"><h3>${esc(type.replaceAll('_',' '))}</h3>${numberField(type,'minimumFare','Minimum fare',v.minimumFare)}${numberField(type,'includedKm','Included kilometres',v.includedKm)}${numberField(type,'additionalStepKm','Additional step (km)',v.additionalStepKm)}${numberField(type,'additionalStepFare','Fare per step',v.additionalStepFare)}${numberField(type,'companyCommissionPercent','Company commission %',v.companyCommissionPercent)}${numberField(type,'companyCommissionMaximum','Commission maximum',v.companyCommissionMaximum)}${numberField(type,'promoterShareOfCompanyCommissionPercent','Promoter share of company commission %',v.promoterShareOfCompanyCommissionPercent)}${numberField(type,'areaPromoterShareOfCompanyCommissionPercent','Area promoter share %',v.areaPromoterShareOfCompanyCommissionPercent)}</section>`).join('')}</div><div class="panel soft-panel"><h3>Distance & waiting rules</h3><div class="form-grid">${simpleNumber('maximumTotoDistanceKm','Maximum Toto distance (km)',c.businessRules.maximumTotoDistanceKm)}${simpleNumber('outsideStepFare','Outside-area fare per step',c.businessRules.outsideArea.stepFare)}${simpleNumber('returnCompensationPercent','Return compensation %',c.businessRules.outsideArea.returnCompensationPercent)}${simpleNumber('freeWaitingMinutes','Free waiting minutes',c.businessRules.waiting.freeMinutes)}${simpleNumber('waitingPerMinute','Waiting charge/minute',c.businessRules.waiting.perMinute)}${simpleNumber('waitingMaxCharge','Maximum waiting charge',c.businessRules.waiting.maxCharge)}</div></div></div>`},
async dynamicPricing(){const c=await api('/v1/admin/config'),d=c.businessRules.dynamicPricing;return `<div class="grid"><div class="panel"><div class="panel-header"><h3>Demand-based pricing</h3>${badge(d.enabled?'ON':'OFF')}</div>${toggle('dynamicPricingEnabled',d.enabled)}<div class="form-grid">${simpleNumber('dynamicMaxMultiplier','Maximum multiplier',d.maxMultiplier,0.01)}<label class="field full"><span>Dynamic zones (comma separated)</span><input id="dynamicZones" value="${esc(d.zones.join(', '))}"></label></div><div class="actions"><button class="primary" id="saveDynamic">${tr('save')}</button></div></div><div class="panel"><h3>Peak windows</h3><div id="peakWindows">${d.peakWindows.map((w,i)=>`<div class="time-row"><b>Window ${i+1}</b><input type="time" data-peak-start value="${esc(w.start)}"><span>to</span><input type="time" data-peak-end value="${esc(w.end)}"></div>`).join('')}</div><p class="muted">Applied only in configured high-demand zones such as railway stations and bus stands.</p></div></div>`},
async nightService(){const c=await api('/v1/admin/config'),n=c.businessRules.nightService,r=c.businessRules.rideTypes;return `<div class="grid"><div class="panel"><div class="panel-header"><h3>Night service window</h3>${badge(n.enabled?'ACTIVE':'OFF')}</div>${toggle('nightServiceEnabled',n.enabled)}<div class="form-grid"><label class="field"><span>Starts</span><input id="nightStart" type="time" value="${esc(n.start)}"></label><label class="field"><span>Ends</span><input id="nightEnd" type="time" value="${esc(n.end)}"></label></div><div class="switch-row"><span>Share Toto available at night</span>${badge(n.shareTotoAllowed?'YES':'NO')}</div><div class="switch-row"><span>Motorcycle requires eligible driver</span>${badge(n.motorcycleRequiresAvailability?'YES':'NO')}</div></div><div class="panel"><h3>Night surcharge</h3>${Object.entries(r).map(([k,v])=>numberField(k,'nightSurchargePercent',`${k.replaceAll('_',' ')} surcharge %`,v.nightSurchargePercent)).join('')}<div class="actions"><button class="primary" id="saveNight">${tr('save')}</button></div></div></div>`},
async zoneManager(){const c=await api('/v1/admin/config'),routes=await api('/v1/admin/share/routes');return `<div class="grid"><div class="panel"><h3>Zone & GeoJSON Manager</h3><div class="map-placeholder"><div class="map-grid"></div><div class="zone-chip service">GeoJSON service zones</div><div class="zone-chip risk">100m tolerance</div><p>Draw/import Municipality, Block and sub-zone polygons. Zone coordinates stay provider-neutral.</p></div><div class="actions"><button class="secondary" id="addServiceZone">＋ Add service polygon</button><button class="secondary" id="addRiskZone">＋ Add risk zone</button></div></div><div class="panel"><h3>Dual operating rules</h3><div class="switch-row"><span>Full Toto</span><b>Primary zone + cross-border warning</b></div><div class="switch-row"><span>Share Toto</span><b>Multi-zone + approved route + seat pooling</b></div><div class="switch-row"><span>Boundary tolerance</span><b>100 metres configurable</b></div><div class="switch-row"><span>Maximum Toto distance</span><b>${esc(c.businessRules.maximumTotoDistanceKm)} km</b></div></div></div><div class="panel"><div class="panel-header"><h3>Share Route Builder</h3>${badge(`${routes.items.length} routes`)}</div><div class="form-grid"><label class="field"><span>Route name</span><input id="shareRouteName" placeholder="Nibhuji to Kalna Ferry Ghat"></label><label class="field"><span>Vehicle capacity</span><input id="shareRouteCapacity" type="number" min="1" value="4"></label><label class="field full"><span>Stops JSON (ordered)</span><textarea id="shareRouteStops" rows="10" placeholder='[{"name":"নিভুজি","lat":23.00,"lng":88.00,"zoneId":"..."},{"name":"হাসপাতাল মোড়","lat":23.01,"lng":88.01}]'></textarea></label></div><div class="actions"><button class="primary" id="saveShareRoute">Save share route</button></div><div class="table-wrap"><table><thead><tr><th>Route</th><th>Stops</th><th>Capacity</th><th>Zones</th></tr></thead><tbody>${routes.items.map(r=>`<tr><td><b>${esc(r.name)}</b><br><span class="muted">${esc(r.code)}</span></td><td>${r.stops.map(x=>esc(x.name)).join(' → ')}</td><td>${r.defaultCapacity}</td><td>${(r.allowedZoneIds||[]).length}</td></tr>`).join('')||'<tr><td colspan="4">No share route configured</td></tr>'}</tbody></table></div></div>`},
async referrals(){
  const d=await api('/v1/admin/referrals');
  const s=d.summary||{};
  const rules=d.rewardRules||{};
  return `
    <div class="cards">
      <div class="card"><small>Referral Profiles</small><strong>${esc(s.totalReferralProfiles||0)}</strong></div>
      <div class="card"><small>Total Invited</small><strong>${esc(s.totalInvited||0)}</strong></div>
      <div class="card"><small>Signed Up</small><strong>${esc(s.signedUp||0)}</strong></div>
      <div class="card"><small>Rewarded</small><strong>${esc(s.rewarded||0)}</strong></div>
      <div class="card"><small>Rewards Earned</small><strong>₹${((s.earnedRewardPaise||0)/100).toFixed(2)}</strong></div>
      <div class="card"><small>Pending Rewards</small><strong>₹${((s.pendingRewardPaise||0)/100).toFixed(2)}</strong></div>
    </div>
    <div class="grid">
      <div class="panel">
        <div class="panel-header">
          <h3>Current Reward Rules</h3>
          <span class="badge good">ACTIVE</span>
        </div>
        <div class="switch-row">
          <span>Referrer reward</span>
          <b>₹${((rules.referrerRewardPaise||0)/100).toFixed(2)}</b>
        </div>
        <div class="switch-row">
          <span>New passenger reward</span>
          <b>₹${((rules.newUserRewardPaise||0)/100).toFixed(2)}</b>
        </div>
        <p class="muted">Rewards are credited after the referred passenger completes the first eligible ride.</p>
      </div>
      <div class="panel">
        <h3>Referral Protection</h3>
        <div class="switch-row"><span>Self-referral prevention</span>${badge('ON')}</div>
        <div class="switch-row"><span>Duplicate referral prevention</span>${badge('ON')}</div>
        <div class="switch-row"><span>First-ride eligibility</span>${badge('ON')}</div>
        <div class="switch-row"><span>Wallet credit idempotency</span>${badge('ON')}</div>
      </div>
    </div>
    <div class="panel">
      <div class="panel-header">
        <h3>Referral Activity</h3>
        <button class="secondary" id="refreshReferrals">Refresh</button>
      </div>
      ${table(d.items||[],[
        ['Code',x=>`<b>${esc(x.referralCode||'-')}</b>`],
        ['Referrer',x=>`<span class="mono">${esc(x.referrerPassengerId||'-')}</span>`],
        ['Referred Passenger',x=>`<span class="mono">${esc(x.referredPassengerId||'-')}</span>`],
        ['Mobile',x=>esc(x.referredMobile||'-')],
        ['Status',x=>badge(x.status||'-')],
        ['Referrer Reward',x=>`₹${((x.referrerRewardPaise||0)/100).toFixed(2)}`],
        ['New User Reward',x=>`₹${((x.referredRewardPaise||0)/100).toFixed(2)}`],
        ['First Ride',x=>esc(x.firstRideId||'-')],
        ['Created',x=>esc(x.createdAt||'-')]
      ])}
    </div>`;
},
async campaigns(){const d=await api('/v1/admin/campaigns');const summary=d.summary||{};return `<div class="cards"><div class="card"><small>Total Campaigns</small><strong>${esc(summary.total||0)}</strong></div><div class="card"><small>Active</small><strong>${esc(summary.active||0)}</strong></div><div class="card"><small>Total Payout</small><strong>₹${esc(summary.totalPayout||0)}</strong></div><div class="card"><small>Redemptions</small><strong>${esc(summary.redemptions||0)}</strong></div></div><div class="grid"><div class="panel"><h3>Create Offer / Campaign</h3><div class="form-grid"><label class="field"><span>Offer Name</span><input id="campaignName" placeholder="Launch Bonus"></label><label class="field"><span>Offer Code (optional)</span><input id="campaignCode" placeholder="FIRST20"></label><label class="field"><span>Target User</span><select id="campaignTarget"><option>DRIVER</option><option>PASSENGER</option><option>PROMOTER</option><option>AREA_PROMOTER</option></select></label><label class="field"><span>Status</span><select id="campaignStatus"><option>DRAFT</option><option>SCHEDULED</option><option>ACTIVE</option></select></label><label class="field"><span>Start Date</span><input id="campaignStart" type="datetime-local"></label><label class="field"><span>End Date</span><input id="campaignEnd" type="datetime-local"></label><label class="field"><span>Reward Type</span><select id="campaignRewardType"><option>FIXED_BONUS</option><option>FLAT_DISCOUNT</option><option>PERCENT_DISCOUNT</option><option>CASHBACK</option><option>ZERO_COMMISSION</option><option>TARGET_BONUS</option><option>REFERRAL_BONUS</option></select></label><label class="field"><span>Reward Value (₹ or %)</span><input id="campaignRewardValue" type="number" step="0.01" value="0"></label><label class="field"><span>Target Count</span><input id="campaignRequiredCount" type="number" value="1"></label><label class="field"><span>Metric</span><select id="campaignMetric"><option>RIDE_COMPLETED</option><option>DRIVER_ONBOARDED</option><option>REFERRAL_COMPLETED</option><option>NIGHT_RIDE_COMPLETED</option><option>PEAK_RIDE_COMPLETED</option><option>AREA_DRIVER_ACTIVE</option></select></label><label class="field"><span>Area / Zone IDs</span><input id="campaignAreas" placeholder="zone-kalna,zone-block1"></label><label class="field"><span>Ride Types</span><input id="campaignRideTypes" placeholder="FULL_TOTO,SHARE_TOTO"></label><label class="field"><span>Maximum Payout (₹)</span><input id="campaignBudget" type="number" step="0.01" value="0"></label><label class="field"><span>Per-user Limit</span><input id="campaignUserLimit" type="number" value="1"></label></div><label class="field"><span>Terms & Conditions</span><textarea id="campaignTerms" rows="4"></textarea></label><button class="primary" id="saveCampaign">Create Campaign</button></div><div class="panel"><h3>Campaign Controls</h3><p class="muted">Dates, targeting, reward rules and maximum payout are enforced by the backend. Payouts stop automatically when the budget is exhausted.</p><label class="field"><span>Filter Target</span><select id="campaignFilter"><option value="">All</option><option>DRIVER</option><option>PASSENGER</option><option>PROMOTER</option><option>AREA_PROMOTER</option></select></label></div></div><div id="campaignTable">${campaignTable(d.items)}</div>`},
async promoterManagement(){
  const d=await api('/v1/admin/promoters');
  const items=d.items||[];
  const areas=items.filter(x=>
    x.role==='AREA_PROMOTER'&&x.status==='ACTIVE'
  );
  const areaOptions=areas.map(x=>
    `<option value="${esc(x.id)}">${esc(x.name||x.id)} · ${esc(x.areaId||'No area')}</option>`
  ).join('');
  return `
    <div class="toolbar">
      <input id="promoterSearch" placeholder="Search promoter / area / mobile">
      <select id="promoterRole">
        <option value="">All roles</option>
        <option value="PROMOTER">PROMOTER</option>
        <option value="AREA_PROMOTER">AREA_PROMOTER</option>
      </select>
      <select id="promoterStatusFilter">
        <option value="">All status</option>
        <option value="ACTIVE">ACTIVE</option>
        <option value="SUSPENDED">SUSPENDED</option>
        <option value="TERMINATED">TERMINATED</option>
      </select>
      <button class="primary" id="addPromoter">＋ Add Partner</button>
    </div>
    <div id="partnerCreatePanel" class="panel creation-panel" hidden>
      <div class="panel-header">
        <div>
          <h3>Create Partner Account</h3>
          <p class="muted">Only Admin creates and assigns partner hierarchy.</p>
        </div>
        <button class="secondary" id="closePartnerForm">Close</button>
      </div>
      <div class="form-grid">
        <label class="field"><span>Name *</span><input id="partnerName"></label>
        <label class="field"><span>Mobile number *</span><input id="partnerMobile" inputmode="numeric"></label>
        <label class="field"><span>Partner ID</span><input id="partnerLoginId" placeholder="Auto if left blank"></label>
        <label class="field"><span>Role *</span>
          <select id="partnerCreateRole">
            <option value="PROMOTER">Promoter</option>
            <option value="AREA_PROMOTER">Area Promoter</option>
          </select>
        </label>
        <label class="field"><span>Area ID</span><input id="partnerAreaId"></label>
        <label class="field" id="partnerParentField"><span>Assign under Area Promoter</span>
          <select id="partnerParentId">
            <option value="">Not assigned — assign later</option>
            ${areaOptions}
          </select>
        </label>
        <label class="field"><span>Temporary password *</span><input id="partnerTempPassword" type="password" minlength="8"></label>
      </div>
      <div class="actions">
        <button class="primary" id="createPartnerAccount">Create Partner Account</button>
      </div>
      <pre id="partnerCreateResult" class="result-box" hidden></pre>
    </div>
    <div id="promoterTable">${promoterTable(items,areas)}</div>`;
},
async compensation(){const c=await api('/v1/admin/config'),l=c.businessRules.lateArrival,w=c.businessRules.waiting;return `<div class="cards"><div class="card"><small>Grace period</small><strong>${esc(l.graceMinutes)} min</strong></div><div class="card"><small>Late penalty/min</small><strong>₹${esc(l.perMinutePenalty)}</strong></div><div class="card"><small>Maximum penalty</small><strong>₹${esc(l.maxPenalty)}</strong></div><div class="card"><small>Free waiting</small><strong>${esc(w.freeMinutes)} min</strong></div></div><div class="grid"><div class="panel"><h3>Late-arrival policy</h3>${toggle('lateArrivalEnabled',l.enabled)}<div class="form-grid">${simpleNumber('lateGrace','Grace minutes',l.graceMinutes)}${simpleNumber('lateFlat','Flat penalty',l.flatPenalty)}${simpleNumber('latePerMinute','Penalty per late minute',l.perMinutePenalty)}${simpleNumber('lateMaximum','Maximum penalty',l.maxPenalty)}</div><div class="actions"><button id="saveCompensation" class="primary">${tr('save')}</button></div></div><div class="panel"><h3>Compensation simulator</h3><div class="form-grid"><label class="field"><span>Committed arrival</span><input id="committedAt" type="datetime-local"></label><label class="field"><span>Actual arrival</span><input id="actualAt" type="datetime-local"></label></div><div class="actions"><button id="simulateLate" class="secondary">Calculate</button></div><pre id="lateResult" class="result-box">No calculation yet.</pre></div></div>`},
async saferideAdmin(){const c=await api('/v1/admin/config'),s=c.businessRules.saferide;return `<div class="grid"><div class="panel"><div class="panel-header"><h3>SafeRide controls</h3>${badge(s.enabled?'ACTIVE':'OFF')}</div>${toggle('saferideEnabled',s.enabled)}${toggle('saferideAlwaysVisible',s.alwaysVisible)}${toggle('saferideNightSuggest',s.nightSuggest)}${toggle('saferideRiskPrompt',s.highRiskZonePrompt)}${toggle('saferideTrustedPriority',s.trustedDriverPriority)}<div class="actions"><button class="primary" id="saveSafeRide">${tr('save')}</button></div></div><div class="panel"><h3>Passenger safety experience</h3><ul class="feature-list"><li>Trusted verified driver priority</li><li>Live trip sharing</li><li>Route deviation monitoring</li><li>Emergency-contact alert</li><li>One-tap SOS and ride replay</li></ul><div class="notice night">Night bookings automatically receive a prominent SafeRide recommendation.</div><div class="notice risk">High-risk pickup zones display a stronger safety prompt.</div></div></div>`},
async partnerSettlements(){const [p,c]=await Promise.all([api('/v1/admin/promoters'),api('/v1/admin/config')]);return `<div class="panel"><div class="panel-header"><div><h3>Monthly Partner Settlement</h3><p class="muted">Cycle: ${esc(c.businessRules.promoterSettlement.cycle)} · withdrawal opens day ${esc(c.businessRules.promoterSettlement.withdrawalOpenDay)}</p></div><button class="primary" id="releasePartnerEarnings">Release month</button></div><label class="field month-field"><span>Settlement month</span><input id="partnerMonth" type="month"></label>${table(p.items,[['Partner',x=>`<b>${esc(x.fullName||x.name||x.id)}</b><div class="mono muted">${esc(x.id)}</div>`],['Role',x=>badge(x.role)],['Area',x=>esc(x.areaId||'-')],['Status',x=>badge(x.status||'ACTIVE')],['Withdrawal',x=>badge('MONTH LOCKED')]])}</div>`}
}
function numberField(type,key,label,value){return `<label class="field"><span>${esc(label)}</span><input type="number" step="0.01" data-fare-type="${esc(type)}" data-fare-key="${esc(key)}" value="${esc(value)}"></label>`}
function simpleNumber(id,label,value,step=1){return `<label class="field"><span>${esc(label)}</span><input id="${esc(id)}" type="number" step="${step}" value="${esc(value)}"></label>`}
function campaignTable(items){return table(items,[['Offer',x=>`<b>${esc(x.offerName)}</b><div class="mono muted">${esc(x.offerCode||x.id)}</div>`],['Target',x=>badge(x.targetUser)],['Status',x=>badge(x.effectiveStatus||x.status)],['Reward',x=>`${esc(x.rewardType)} · ${esc(x.rewardValue)}`],['Progress',x=>`${esc(x.redemptionCount||0)} redemption(s)<br><span class="muted">₹${esc(x.payoutAmount||0)} / ${esc(x.maximumPayout||'∞')}</span>`],['Period',x=>`${esc(x.startDate||'-')}<br>${esc(x.endDate||'-')}`],['Action',x=>`<button class="secondary campaign-toggle" data-id="${esc(x.id)}" data-status="${(x.effectiveStatus||x.status)==='ACTIVE'?'PAUSED':'ACTIVE'}">${(x.effectiveStatus||x.status)==='ACTIVE'?'Pause':'Activate'}</button>`]])}
function renderDriverVerification(data,promoters=[]){
  const profile=data.profile||{},documents=data.documents||[],verification=data.verification||{},approval=data.approval||{},assignment=data.assignment||{};
  const currentPromoterId=assignment.promoter?.id||approval.promoterId||'';
  const promoterOptions=promoters.map(x=>`<option value="${esc(x.id)}" ${x.id===currentPromoterId?'selected':''}>${esc(x.name||x.id)} · ${esc(x.mobile||x.id)}</option>`).join('');
  const labels={IDENTITY_DOCUMENT:'Identity document',VEHICLE_REGISTRATION:'Vehicle registration',VEHICLE_PHOTO:'Vehicle photo',PROFILE_PHOTO:'Driver profile photo',BANK_DETAILS:'Bank passbook / cancelled cheque'};
  const stageCard=(title,stage,note='')=>`<article class="approval-stage-card"><div class="document-review-head"><h4>${esc(title)}</h4>${badge(stage?.status||'PENDING')}</div><p class="muted">${esc(stage?.remarks||note||'No remarks')}</p>${stage?.reviewedAt?`<small class="muted">${esc(stage.reviewedAt)} · ${esc(stage.reviewedBy||'')}</small>`:''}</article>`;
  const required=(verification.required||[]).map(item=>{const document=[...documents].reverse().find(doc=>doc.type===item.type);if(!document)return `<article class="document-review-card missing"><div><h4>${esc(labels[item.type]||item.type)}</h4><p class="muted">Document has not been uploaded.</p></div>${badge('MISSING')}</article>`;const remarksId=`docRemark_${document.id}`;return `<article class="document-review-card"><div class="document-review-head"><div><h4>${esc(labels[document.type]||document.type)}</h4><p class="muted mono">${esc(document.id)}</p></div>${badge(document.status||'PENDING')}</div><div class="document-review-actions"><a class="secondary button-link" href="${esc(fileHref(document.fileUrl))}" target="_blank" rel="noopener">Open document</a><input id="${esc(remarksId)}" placeholder="Admin document remarks / rejection reason" value="${esc(document.remarks||'')}"><button class="secondary review-document" data-driver="${esc(profile.id)}" data-document="${esc(document.id)}" data-status="APPROVED" data-remarks="${esc(remarksId)}">Final verify</button><button class="danger review-document" data-driver="${esc(profile.id)}" data-document="${esc(document.id)}" data-status="REJECTED" data-remarks="${esc(remarksId)}">Reject</button></div></article>`;}).join('');
  const directReady=approval.canAdminApprove===true,bypassReady=approval.canAdminApproveWithBypass===true,promoterReady=approval.promoterApproved===true;
  return `<div class="panel-header"><div><h3>Final Driver Approval</h3><p class="muted"><b>${esc(profile.fullName||profile.id)}</b> · ${esc(profile.mobile||'-')} · ${esc(profile.vehicle?.number||profile.vehicleNumber||'-')}</p></div><button class="secondary" id="closeDriverReview">Close</button></div>
  <section class="assignment-card"><div><h4>Driver hierarchy assignment</h4><p class="muted">Every Driver must remain under a Promoter. Reassignment resets stage approvals but keeps uploaded documents.</p></div><div class="assignment-grid"><label class="field"><span>Promoter *</span><select id="assignDriverPromoter"><option value="">Select an active Promoter</option>${promoterOptions}</select></label><div class="assignment-current"><small>Currently assigned</small><b>${esc(assignment.promoter?.name||'Not assigned')}</b><span class="mono muted">${esc(assignment.promoter?.id||'-')}</span><small>Area Promoter: ${esc(assignment.areaPromoter?.name||assignment.areaPromoter?.id||'Not assigned — Admin bypass may be used later')}</small></div><button class="secondary" id="assignDriverPromoterButton" data-driver="${esc(profile.id)}">${assignment.promoter?'Reassign Promoter':'Assign Promoter'}</button></div></section>
  <div class="approval-chain-grid">${stageCard('1. Promoter partial approval',approval.promoter,'Assigned Promoter must pre-approve the Driver.')}${stageCard('2. Area Promoter approval',approval.areaPromoter,'Area Promoter reviews after Promoter approval.')}${stageCard('3. Admin final approval',approval.admin,'Only Admin activates the Driver.')}</div>
  <div class="verification-summary"><div>${badge(profile.status||'DRAFT')}<span>Driver status</span></div><div>${verificationBadge(verification)}<span>Admin document verification</span></div><div><strong>${esc(verification.approvedCount||0)}/${esc(verification.requiredCount||5)}</strong><span>Final-verified documents</span></div></div><div class="verification-grid">${required}</div>
  <div class="approval-checklist">
    <h4>Final approval checklist</h4>
    <div>${approval.promoterAssigned?badge('OK'):badge('MISSING')}<span>Promoter assigned</span></div>
    <div>${approval.allDocumentsUploaded?badge('OK'):badge('MISSING')}<span>All documents uploaded</span></div>
    <div>${approval.promoterApproved?badge('OK'):badge('PENDING')}<span>Promoter partial approval</span></div>
    <div>${approval.areaApproved?badge('OK'):badge('PENDING')}<span>Area approval / Admin bypass</span></div>
    <div>${approval.documentsFinalApproved?badge('OK'):badge('PENDING')}<span>Admin document verification</span></div>
  </div>
  <div class="overall-review">
    <label class="field full"><span>Review / suspension / bypass reason</span>
      <textarea id="driverReviewRemarks" rows="3" placeholder="Reason required for Suspend, Reject and Area bypass">${esc(profile.reviewRemarks||'')}</textarea>
    </label>
    <div class="actions">
      ${profile.suspended||profile.status==='SUSPENDED'
        ?`<button class="primary review-driver-status" data-driver="${esc(profile.id)}" data-status="REACTIVATE" data-bypass="false">Lift Suspension & Approve</button>`
        :`<button class="primary review-driver-status" data-driver="${esc(profile.id)}" data-status="APPROVED" data-bypass="false" ${directReady?'':'disabled'}>Final Approve</button>
          <button class="secondary review-driver-status" data-driver="${esc(profile.id)}" data-status="APPROVED" data-bypass="true" ${bypassReady?'':'disabled'}>Approve without Area Promoter</button>`}
      <button class="danger review-driver-status" data-driver="${esc(profile.id)}" data-status="REJECTED" data-bypass="false">Reject Driver</button>
      ${profile.suspended||profile.status==='SUSPENDED'
        ?''
        :`<button class="secondary review-driver-status" data-driver="${esc(profile.id)}" data-status="SUSPENDED" data-bypass="false">Suspend Driver</button>`}
    </div>
    ${!approval.promoterAssigned?'<p class="muted">Assign a Promoter first.</p>':''}
    ${approval.promoterAssigned&&!promoterReady?'<p class="muted">Promoter partial approval is pending in the Promoter App.</p>':''}
    ${promoterReady&&!directReady&&!bypassReady?'<p class="muted">Final-verify all five documents first.</p>':''}
    ${bypassReady?'<p class="muted">Area approval is pending. Enter a reason and use the bypass button.</p>':''}
  </div>`;
}

function promoterTable(items,areas=[]){
  const options=current=>areas.map(x=>
    `<option value="${esc(x.id)}" ${x.id===current?'selected':''}>${esc(x.name||x.id)}</option>`
  ).join('');
  return table(items,[
    ['Partner',x=>`<b>${esc(x.name||x.id)}</b><div class="mono muted">${esc(x.mobile||x.id)}</div>`],
    ['Role',x=>badge(x.role)],
    ['Area',x=>esc(x.areaId||'-')],
    ['Area Promoter',x=>x.role==='PROMOTER'
      ?`<select class="partner-area-select" data-id="${esc(x.id)}">
          <option value="">Select Area Promoter</option>
          ${options(x.areaPromoterId)}
        </select>
        <button class="secondary assign-partner-area" data-id="${esc(x.id)}">Assign</button>`
      :'-'],
    ['Status',x=>badge(x.status||'ACTIVE')],
    ['Drivers',x=>esc((x.driverIds||[]).length)],
    ['Actions',x=>{
      const status=String(x.status||'ACTIVE');
      if(status==='TERMINATED')return '<span class="muted">Permanent</span>';
      return `${status==='ACTIVE'
        ?`<button class="secondary partner-status" data-id="${esc(x.id)}" data-status="SUSPENDED">Suspend</button>`
        :`<button class="primary partner-status" data-id="${esc(x.id)}" data-status="ACTIVE">Reactivate</button>`}
        <button class="danger partner-status" data-id="${esc(x.id)}" data-status="TERMINATED">Terminate</button>`;
    }],
  ]);
}

function rideTable(items){return table(items,[['Ride',x=>`<span class="mono">${esc(x.id)}</span><div class="muted compact-note">${esc(x.pickupAddress||'Pickup coordinates recorded')}</div>`],['Status',x=>badge(x.status)],['Passenger',x=>esc(x.passengerId)],['Driver',x=>esc(x.driverId||'-')],['Fare',x=>esc(x.fareEstimate?.amount||x.fareEstimate?.amountPaise/100||'-')],['Created',x=>esc(x.createdAt||'-')],['Dispatch',x=>`<button class="secondary open-dispatch" data-id="${esc(x.id)}">Map & Assign</button>`]])}
function providerSelect(key,label,opts,current){return `<label class="field"><span>${label}</span><select data-provider="${key}">${opts.map(x=>`<option value="${x}" ${current.active===x?'selected':''}>${x}</option>`).join('')}</select></label><label class="field"><span>${label} mode</span><select data-mode="${key}"><option value="test" ${current.mode==='test'?'selected':''}>test</option><option value="live" ${current.mode==='live'?'selected':''}>live</option></select></label>`}
function toggle(k,v){return `<div class="switch-row"><span>${esc(k)}</span><label class="switch"><input type="checkbox" data-op="${esc(k)}" ${v?'checked':''}><span></span></label></div>`}
function wire(page){if(page==='referrals'&&$('#refreshReferrals'))$('#refreshReferrals').onclick=()=>loadPage('referrals');
if(page==='rides'){
  let selectedRideId=null;
  const bindRideButtons=()=>{
    $$('.open-dispatch').forEach(button=>{
      button.onclick=()=>openDispatch(button.dataset.id);
    });
  };
  const refreshTable=async()=>{
    const d=await api('/v1/admin/rides');
    const q=($('#q')?.value||'').toLowerCase();
    const status=$('#statusFilter')?.value||'';
    const items=(d.items||[]).filter(x=>
      (!status||x.status===status)&&
      JSON.stringify(x).toLowerCase().includes(q)
    );
    $('#rideTable').innerHTML=rideTable(items);
    bindRideButtons();
  };
  const openDispatch=async rideId=>{
    selectedRideId=rideId;
    const panel=$('#rideDispatchPanel');
    panel.hidden=false;
    panel.innerHTML='<div class="loading">Loading live dispatch map…</div>';
    try{
      const data=await api(
        `/v1/admin/rides/${encodeURIComponent(rideId)}/dispatch`,
      );
      if(selectedRideId!==rideId||state.page!=='rides')return;
      panel.innerHTML=dispatchPanel(data);
      await drawDispatchMap(data);
      $('#closeDispatch').onclick=()=>{
        selectedRideId=null;
        panel.hidden=true;
        panel.innerHTML='';
        if(state.dispatchMap){
          state.dispatchMap.remove();
          state.dispatchMap=null;
        }
      };
      $$('.manual-assign-driver').forEach(button=>{
        button.onclick=async()=>{
          try{
            await api(
              `/v1/admin/rides/${encodeURIComponent(rideId)}/assign`,
              {
                method:'POST',
                body:JSON.stringify({
                  driverId:button.dataset.driver,
                }),
              },
            );
            toast('Driver assigned successfully');
            await refreshTable();
            await openDispatch(rideId);
          }catch(error){toast(error.message)}
        };
      });
      const auto=$('#autoAssignNearest');
      if(auto){
        auto.onclick=async()=>{
          try{
            await api(
              `/v1/bookings/${encodeURIComponent(rideId)}/match`,
              {method:'POST',body:'{}'},
            );
            toast('Nearest eligible Driver assigned');
            await refreshTable();
            await openDispatch(rideId);
          }catch(error){toast(error.message)}
        };
      }
    }catch(error){
      panel.innerHTML=`<div class="danger-strip"><h3>Dispatch data unavailable</h3><p>${esc(error.message)}</p></div>`;
    }
  };
  $('#q').oninput=refreshTable;
  $('#statusFilter').onchange=refreshTable;
  $('#refreshLiveRides').onclick=async()=>{
    await refreshTable();
    if(selectedRideId)await openDispatch(selectedRideId);
  };
  bindRideButtons();
  state.dispatchTimer=setInterval(()=>{
    if(state.page!=='rides'){
      clearInterval(state.dispatchTimer);
      state.dispatchTimer=null;
      return;
    }
    refreshTable();
    if(selectedRideId)openDispatch(selectedRideId);
  },5000);
}
if(page==='payments')$('#reconcileAll').onclick=async()=>{const r=await api('/v1/admin/payments/reconcile',{method:'POST',body:'{}'});toast(`Reconciled ${r.items.length} payment(s)`);loadPage(page)};
if(page==='safety')$$('.resolve-sos').forEach(b=>b.onclick=async()=>{await api(`/v1/admin/sos/${b.dataset.id}`,{method:'PATCH',body:JSON.stringify({status:'RESOLVED',resolution:'Resolved from control console'})});toast('SOS resolved');loadPage(page)});
if(page==='complaints')$$('.close-complaint').forEach(b=>b.onclick=async()=>{await api(`/v1/admin/complaints/${b.dataset.id}`,{method:'PATCH',body:JSON.stringify({status:'CLOSED'})});toast('Complaint closed');loadPage(page)});
if(page==='providers'){$('#saveProviders').onclick=async()=>{const providers={};$$('[data-provider]').forEach(x=>providers[x.dataset.provider]={active:x.value,mode:$(`[data-mode="${x.dataset.provider}"]`).value});await api('/v1/admin/config',{method:'PATCH',body:JSON.stringify({providers})});toast('Providers updated')};$('#saveCredential').onclick=async()=>{let credentials;try{credentials=JSON.parse($('#credentialJson').value)}catch{return toast('Credential JSON is invalid')}await api('/v1/admin/providers/credentials',{method:'PUT',body:JSON.stringify({type:$('#credentialType').value,name:$('#credentialName').value.trim(),mode:$('#credentialMode').value,credentials})});toast('Credentials encrypted and saved');loadPage(page)};$('#deleteCredential').onclick=async()=>{await api('/v1/admin/providers/credentials',{method:'DELETE',body:JSON.stringify({type:$('#credentialType').value,name:$('#credentialName').value.trim(),mode:$('#credentialMode').value})});toast('Credentials deleted');loadPage(page)};$('#testProvider').onclick=async()=>{const r=await api('/v1/admin/providers/test',{method:'POST',body:JSON.stringify({type:$('#testType').value,name:$('#testName').value,mode:$('#testMode').value})});$('#testResult').textContent=JSON.stringify(r,null,2)}}
if(page==='settings')$('#saveOps').onclick=async()=>{const operations={};$$('[data-op]').forEach(x=>operations[x.dataset.op]=x.checked);await api('/v1/admin/config',{method:'PATCH',body:JSON.stringify({operations})});toast('Service controls updated')};

if(page==='fareManagement')$('#saveFareRules').onclick=async()=>{const rideTypes={};$$('[data-fare-type]').forEach(x=>{rideTypes[x.dataset.fareType]??={};rideTypes[x.dataset.fareType][x.dataset.fareKey]=Number(x.value)});const businessRules={rideTypes,maximumTotoDistanceKm:Number($('#maximumTotoDistanceKm').value),outsideArea:{stepFare:Number($('#outsideStepFare').value),returnCompensationPercent:Number($('#returnCompensationPercent').value)},waiting:{freeMinutes:Number($('#freeWaitingMinutes').value),perMinute:Number($('#waitingPerMinute').value),maxCharge:Number($('#waitingMaxCharge').value)}};await api('/v1/admin/config',{method:'PATCH',body:JSON.stringify({businessRules})});toast('Fare rules saved');loadPage(page)};
if(page==='dynamicPricing')$('#saveDynamic').onclick=async()=>{const peakWindows=$$('[data-peak-start]').map((x,i)=>({start:x.value,end:$$('[data-peak-end]')[i].value}));const businessRules={dynamicPricing:{enabled:$('[data-op="dynamicPricingEnabled"]').checked,maxMultiplier:Number($('#dynamicMaxMultiplier').value),zones:$('#dynamicZones').value.split(',').map(x=>x.trim()).filter(Boolean),peakWindows}};await api('/v1/admin/config',{method:'PATCH',body:JSON.stringify({businessRules})});toast('Dynamic pricing saved')};
if(page==='nightService')$('#saveNight').onclick=async()=>{const rideTypes={};$$('[data-fare-key="nightSurchargePercent"]').forEach(x=>{rideTypes[x.dataset.fareType]={nightSurchargePercent:Number(x.value)}});const businessRules={rideTypes,nightService:{enabled:$('[data-op="nightServiceEnabled"]').checked,start:$('#nightStart').value,end:$('#nightEnd').value}};await api('/v1/admin/config',{method:'PATCH',body:JSON.stringify({businessRules})});toast('Night service saved')};
if(page==='zoneManager'){$('#addServiceZone').onclick=()=>toast('Open GeoJSON polygon editor');$('#addRiskZone').onclick=()=>toast('Open risk/tolerance editor');$('#saveShareRoute').onclick=async()=>{let stops;try{stops=JSON.parse($('#shareRouteStops').value)}catch{toast('Stops JSON is invalid');return}await api('/v1/admin/share/routes',{method:'POST',body:JSON.stringify({name:$('#shareRouteName').value,defaultCapacity:Number($('#shareRouteCapacity').value),stops})});toast('Share route saved');await renderPage('zoneManager')}}
if(page==='campaigns'){$('#saveCampaign').onclick=async()=>{const body={offerName:$('#campaignName').value,offerCode:$('#campaignCode').value||null,targetUser:$('#campaignTarget').value,status:$('#campaignStatus').value,startDate:$('#campaignStart').value?new Date($('#campaignStart').value).toISOString():null,endDate:$('#campaignEnd').value?new Date($('#campaignEnd').value).toISOString():null,rewardType:$('#campaignRewardType').value,rewardValue:Number($('#campaignRewardValue').value),requiredCount:Number($('#campaignRequiredCount').value),metric:$('#campaignMetric').value,areaIds:$('#campaignAreas').value.split(',').map(x=>x.trim()).filter(Boolean),rideTypes:$('#campaignRideTypes').value.split(',').map(x=>x.trim()).filter(Boolean),maximumPayout:Number($('#campaignBudget').value)||null,perUserLimit:Number($('#campaignUserLimit').value),termsAndConditions:$('#campaignTerms').value};await api('/v1/admin/campaigns',{method:'POST',body:JSON.stringify(body)});toast('Campaign created');loadPage(page)};$$('.campaign-toggle').forEach(b=>b.onclick=async()=>{await api(`/v1/admin/campaigns/${b.dataset.id}/status`,{method:'POST',body:JSON.stringify({status:b.dataset.status})});toast('Campaign status updated');loadPage(page)});$('#campaignFilter').onchange=async()=>{const d=await api('/v1/admin/campaigns'+($('#campaignFilter').value?`?targetUser=${$('#campaignFilter').value}`:''));$('#campaignTable').innerHTML=campaignTable(d.items);wire(page)}}
if(page==='drivers'){
  const activePromoters=async()=>{const d=await api('/v1/admin/promoters');return(d.items||[]).filter(x=>x.role==='PROMOTER'&&x.status==='ACTIVE')};
  const updateAreaDisplay=(select,display)=>{const areaId=select?.selectedOptions?.[0]?.dataset?.areaPromoter||'';if(display)display.value=areaId?`Auto-assigned Area Promoter: ${areaId}`:'No Area Promoter linked — Admin may bypass later with reason'};
  const bindReviewButtons=()=>{$$('.review-driver').forEach(b=>b.onclick=()=>openDriverReview(b.dataset.id))};
  const refreshDrivers=async()=>{const d=await api('/v1/admin/drivers'),online=new Map((d.availability||[]).map(x=>[x.driverId||x.id,x])),q=($('#driverSearch')?.value||'').toLowerCase(),rows=(d.profiles||[]).filter(x=>JSON.stringify(x).toLowerCase().includes(q));$('#driverTable').innerHTML=driverRows(rows,online);bindReviewButtons()};
  const openDriverReview=async driverId=>{const panel=$('#driverReviewPanel');panel.hidden=false;panel.innerHTML='<div class="loading">Loading verification documents…</div>';panel.scrollIntoView({behavior:'smooth',block:'start'});try{const[detail,promoters]=await Promise.all([api(`/v1/admin/drivers/${encodeURIComponent(driverId)}`),activePromoters()]);panel.innerHTML=renderDriverVerification(detail,promoters);$('#closeDriverReview').onclick=()=>{panel.hidden=true;panel.innerHTML=''};const assign=$('#assignDriverPromoterButton');if(assign)assign.onclick=async()=>{const promoterId=$('#assignDriverPromoter')?.value||'';if(!promoterId)return toast('Select an active Promoter');try{await api(`/v1/admin/drivers/${encodeURIComponent(driverId)}/assign-promoter`,{method:'POST',body:JSON.stringify({promoterId})});toast('Driver assigned under Promoter');await openDriverReview(driverId);await refreshDrivers()}catch(error){toast(error.message)}};$$('.review-document').forEach(button=>{button.onclick=async()=>{const remarksElement=$(`#${button.dataset.remarks}`);try{await api(`/v1/admin/drivers/${encodeURIComponent(button.dataset.driver)}/documents/${encodeURIComponent(button.dataset.document)}/review`,{method:'POST',body:JSON.stringify({status:button.dataset.status,remarks:remarksElement?.value?.trim()||null})});toast(`Document ${button.dataset.status.toLowerCase()}`);await openDriverReview(button.dataset.driver);await refreshDrivers()}catch(error){toast(error.message)}}});$$('.review-driver-status').forEach(button=>{button.onclick=async()=>{const status=button.dataset.status,remarks=$('#driverReviewRemarks')?.value?.trim()||'';if(['SUSPENDED','REJECTED'].includes(status)&&!remarks)return toast('Write the reason first');if(button.dataset.bypass==='true'&&!remarks)return toast('Write the Area Promoter bypass reason first');try{await api(`/v1/admin/drivers/${encodeURIComponent(button.dataset.driver)}/review`,{method:'POST',body:JSON.stringify({status,remarks:remarks||null,bypassArea:button.dataset.bypass==='true'})});toast(status==='REACTIVATE'?'Driver suspension lifted':`Driver ${status.toLowerCase()}`);await openDriverReview(button.dataset.driver);await refreshDrivers()}catch(error){toast(error.message)}}})}catch(error){panel.innerHTML=`<div class="danger-strip"><h3>Unable to load driver verification</h3><p>${esc(error.message)}</p></div>`}};
  $('#driverSearch').oninput=refreshDrivers;bindReviewButtons();$('#addDriver').onclick=()=>{$('#driverCreatePanel').hidden=false;$('#driverCreatePanel').scrollIntoView({behavior:'smooth'})};$('#closeDriverForm').onclick=()=>{$('#driverCreatePanel').hidden=true};const promoterSelect=$('#driverPromoterId'),areaDisplay=$('#driverAreaPromoterDisplay');if(promoterSelect){promoterSelect.onchange=()=>updateAreaDisplay(promoterSelect,areaDisplay);updateAreaDisplay(promoterSelect,areaDisplay)};
  $('#createDriverAccount').onclick=async()=>{const body={fullName:$('#driverFullName').value.trim(),mobile:$('#driverMobile').value.replace(/\D/g,''),loginId:$('#driverLoginId').value.trim()||undefined,temporaryPassword:$('#driverTempPassword').value,promoterId:$('#driverPromoterId').value,areaId:$('#driverAreaId').value.trim()||undefined,primaryZoneId:$('#driverZoneId').value.trim()||undefined,preferredLanguage:$('#driverLanguage').value,vehicle:{number:$('#driverVehicleNumber').value.trim()||undefined,type:$('#driverVehicleType').value}};if(!body.fullName||!body.mobile||body.temporaryPassword.length<8)return toast('Name, mobile and an 8+ character temporary password are required');if(!body.promoterId)return toast('Assign the Driver under an active Promoter');try{const result=await api('/v1/admin/drivers/create',{method:'POST',body:JSON.stringify(body)}),box=$('#driverCreateResult');box.hidden=false;box.textContent=`Driver created successfully\nDriver ID: ${result.driver?.id||'-'}\nLogin ID: ${result.staff?.loginId||result.driver?.id||'-'}\nMobile: ${result.staff?.mobile||body.mobile}\nPromoter: ${result.promoter?.name||result.promoter?.id||'-'}\nArea Promoter: ${result.areaPromoter?.name||result.areaPromoter?.id||'Not assigned — Admin bypass allowed later'}\nMust change password: YES`;toast('Driver account created and assigned');await refreshDrivers()}catch(error){toast(error.message)}};
}
if(page==='promoterManagement'){
  const bind=()=>{
    $$('.assign-partner-area').forEach(button=>{
      button.onclick=async()=>{
        const promoterId=button.dataset.id;
        const areaPromoterId=$(`.partner-area-select[data-id="${promoterId}"]`)?.value||'';
        if(!areaPromoterId)return toast('Select an active Area Promoter');
        try{
          const result=await api(
            `/v1/admin/promoters/${encodeURIComponent(promoterId)}/assign-area`,
            {
              method:'POST',
              body:JSON.stringify({areaPromoterId}),
            },
          );
          toast(`Area assigned; ${result.affectedDriverIds?.length||0} Driver approval chain(s) reset`);
          apply();
        }catch(error){toast(error.message)}
      };
    });
    $$('.partner-status').forEach(button=>{
      button.onclick=async()=>{
        const status=button.dataset.status;
        let reason='';
        if(['SUSPENDED','TERMINATED'].includes(status)){
          reason=prompt(
            status==='SUSPENDED'
              ?'Write suspension reason'
              :'Write termination reason',
          )?.trim()||'';
          if(!reason)return toast('Reason is mandatory');
        }else{
          reason=prompt('Reactivation note (optional)')?.trim()||'';
        }
        try{
          await api(
            `/v1/admin/promoters/${encodeURIComponent(button.dataset.id)}/status`,
            {
              method:'POST',
              body:JSON.stringify({status,reason}),
            },
          );
          toast(`Partner ${status.toLowerCase()}`);
          apply();
        }catch(error){toast(error.message)}
      };
    });
  };

  const apply=async()=>{
    const d=await api('/v1/admin/promoters');
    const all=d.items||[];
    const areas=all.filter(x=>
      x.role==='AREA_PROMOTER'&&x.status==='ACTIVE'
    );
    const q=($('#promoterSearch')?.value||'').toLowerCase();
    const role=$('#promoterRole')?.value||'';
    const status=$('#promoterStatusFilter')?.value||'';
    const filtered=all.filter(x=>
      (!role||x.role===role)&&
      (!status||x.status===status)&&
      JSON.stringify(x).toLowerCase().includes(q)
    );
    $('#promoterTable').innerHTML=promoterTable(filtered,areas);
    bind();
  };

  $('#promoterSearch').oninput=apply;
  $('#promoterRole').onchange=apply;
  $('#promoterStatusFilter').onchange=apply;
  bind();

  const roleSelect=$('#partnerCreateRole');
  const parentField=$('#partnerParentField');
  const toggleParent=()=>{
    if(parentField){
      parentField.hidden=roleSelect?.value==='AREA_PROMOTER';
    }
  };
  roleSelect.onchange=toggleParent;
  toggleParent();

  $('#addPromoter').onclick=()=>{
    $('#partnerCreatePanel').hidden=false;
    $('#partnerCreatePanel').scrollIntoView({behavior:'smooth'});
  };
  $('#closePartnerForm').onclick=()=>{
    $('#partnerCreatePanel').hidden=true;
  };
  $('#createPartnerAccount').onclick=async()=>{
    const role=$('#partnerCreateRole').value;
    const body={
      name:$('#partnerName').value.trim(),
      mobile:$('#partnerMobile').value.replace(/\D/g,''),
      loginId:$('#partnerLoginId').value.trim()||undefined,
      role,
      areaId:$('#partnerAreaId').value.trim()||undefined,
      areaPromoterId:role==='PROMOTER'
        ?($('#partnerParentId').value||undefined)
        :undefined,
      temporaryPassword:$('#partnerTempPassword').value,
    };
    if(!body.name||!body.mobile||body.temporaryPassword.length<8){
      return toast('Name, mobile and an 8+ character temporary password are required');
    }
    try{
      const result=await api('/v1/admin/partners/create',{
        method:'POST',
        body:JSON.stringify(body),
      });
      const box=$('#partnerCreateResult');
      box.hidden=false;
      box.textContent=
        `Partner created successfully\n`+
        `Partner ID: ${result.partner?.id||'-'}\n`+
        `Login ID: ${result.staff?.loginId||result.partner?.id||'-'}\n`+
        `Role: ${result.staff?.role||body.role}\n`+
        `Area Promoter: ${result.areaPromoter?.name||result.areaPromoter?.id||'Not assigned'}\n`+
        `Mobile: ${result.staff?.mobile||body.mobile}\n`+
        `Must change password: YES`;
      toast('Partner account created');
      apply();
    }catch(error){toast(error.message)}
  };
}
if(page==='compensation'){$('#saveCompensation').onclick=async()=>{const businessRules={lateArrival:{enabled:$('[data-op="lateArrivalEnabled"]').checked,graceMinutes:Number($('#lateGrace').value),flatPenalty:Number($('#lateFlat').value),perMinutePenalty:Number($('#latePerMinute').value),maxPenalty:Number($('#lateMaximum').value)}};await api('/v1/admin/config',{method:'PATCH',body:JSON.stringify({businessRules})});toast('Compensation policy saved')};$('#simulateLate').onclick=async()=>{const r=await api('/v1/late-arrival/evaluate',{method:'POST',body:JSON.stringify({committedArrivalAt:new Date($('#committedAt').value).toISOString(),actualArrivalAt:new Date($('#actualAt').value).toISOString()})});$('#lateResult').textContent=JSON.stringify(r,null,2)}}
if(page==='saferideAdmin')$('#saveSafeRide').onclick=async()=>{const businessRules={saferide:{enabled:$('[data-op="saferideEnabled"]').checked,alwaysVisible:$('[data-op="saferideAlwaysVisible"]').checked,nightSuggest:$('[data-op="saferideNightSuggest"]').checked,highRiskZonePrompt:$('[data-op="saferideRiskPrompt"]').checked,trustedDriverPriority:$('[data-op="saferideTrustedPriority"]').checked}};await api('/v1/admin/config',{method:'PATCH',body:JSON.stringify({businessRules})});toast('SafeRide settings saved')};
if(page==='partnerSettlements')$('#releasePartnerEarnings').onclick=async()=>{const month=$('#partnerMonth').value;if(!month)return toast('Select a month');const r=await api('/v1/admin/promoter-earnings/release',{method:'POST',body:JSON.stringify({month})});toast(`Released ${r.released??r.items?.length??0} earning record(s)`);loadPage(page)};
if(page==='audit')$('#flushStorage').onclick=async()=>{await api('/v1/admin/storage/flush',{method:'POST',body:'{}'});toast('Storage flushed');loadPage(page)}}
$('#loginForm').onsubmit=async e=>{e.preventDefault();state.api=$('#apiBase').value.replace(/\/$/,'');localStorage.apiBase=state.api;try{const r=await fetch(state.api+'/v1/admin/auth/login',{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify({username:$('#username').value,password:$('#password').value})});const b=await r.json();if(!r.ok||!b.token)throw Error(b.message||b.error||'Login failed');state.token=b.token;localStorage.adminToken=state.token;showApp()}catch(err){toast(err.message)}};
async function logout(){try{if(state.token)await api('/v1/admin/auth/logout',{method:'POST',body:'{}'})}catch{}state.token='';localStorage.removeItem('adminToken');showApp()}
$('#logout').onclick=logout;$('#refreshAll').onclick=()=>loadPage(state.page);$('#language').value=state.lang;$('#language').onchange=e=>{state.lang=e.target.value;localStorage.adminLang=state.lang;translateShell();loadPage(state.page)};showApp();
