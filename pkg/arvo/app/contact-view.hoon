::  contact-view: sets up contact JS client and combines commands
::  into semantic actions for the UI
::
/-
    group-hook,
    *invite-store,
    *contact-hook,
    *metadata-store,
    *metadata-hook,
    *permission-group-hook,
    *permission-hook
/+  *server, *contact-json, default-agent, dbug, verb,
   group-store
|%
+$  card  card:agent:gall
--
::
%-  agent:dbug
%+  verb  |
^-  agent:gall
=<
  |_  =bowl:gall
  +*  this       .
      contact-core  +>
      cc         ~(. contact-core bowl)
      def        ~(. (default-agent this %|) bowl)
  ::
  ++  on-init
    ^-  (quip card _this)
    :_  this
    :~  [%pass /updates %agent [our.bowl %contact-store] %watch /updates]
        (contact-poke:cc [%create /~/default])
        (contact-poke:cc [%add /~/default our.bowl *contact])
    ==
  ::
  ++  on-save   on-save:def
  ++  on-load
    |=  old=*
    ^-  (quip card _this)
    :_  this
    :~  [%pass / %arvo %e %disconnect [~ /'~groups']]
        [%pass / %arvo %e %connect [~ /'contact-view'] %contact-view]
    ==
  ::
  ++  on-poke
    |=  [=mark =vase]
    ^-  (quip card _this)
    ?>  (team:title our.bowl src.bowl)
    ?+  mark  (on-poke:def mark vase)
        %json                 [(poke-json:cc !<(json vase)) this]
        %contact-view-action
      [(poke-contact-view-action:cc !<(contact-view-action vase)) this]
    ::
        %handle-http-request
      =+  !<([eyre-id=@ta =inbound-request:eyre] vase)
      :_  this
      %+  give-simple-payload:app  eyre-id
      %+  require-authorization:app  inbound-request
      poke-handle-http-request:cc
    ==
  ::
  ++  on-watch
    |=  =path
    ^-  (quip card _this)
    ?>  (team:title our.bowl src.bowl)
    ?:  ?=([%http-response *] path)  [~ this]
    ?.  =(/primary path)  (on-watch:def path)
    [[%give %fact ~ %json !>((rolodex-to-json all-scry:cc))]~ this]
  ::
  ++  on-agent
    |=  [=wire =sign:agent:gall]
    ^-  (quip card _this)
    ?+  -.sign  (on-agent:def wire sign)
        %kick
      [[%pass / %agent [our.bol %contact-store] %watch /updates]~ this]
    ::
        %fact
      ?+  p.cage.sign  (on-agent:def wire sign)
          %contact-update
        =/  update=json  (update-to-json !<(contact-update q.cage.sign))
        [[%give %fact ~[/primary] %json !>(update)]~ this]
      ==
    ==
  ::
  ++  on-arvo
    |=  [=wire =sign-arvo]
    ^-  (quip card _this)
    ?.  ?=(%bound +<.sign-arvo)
      (on-arvo:def wire sign-arvo)
    [~ this]
  ::
  ++  on-leave  on-leave:def
  ++  on-peek   on-peek:def
  ++  on-fail   on-fail:def
  --
::
|_  bol=bowl:gall
++  poke-json
  |=  jon=json
  ^-  (list card)
  ?>  (team:title our.bol src.bol)
  (poke-contact-view-action (json-to-view-action jon))
::
++  poke-contact-view-action
  |=  act=contact-view-action
  ^-  (list card)
  ?>  (team:title our.bol src.bol)
  ?-  -.act
      %create
    =/  =group-id
      [our.bol name.act]
    =/  =path
      (group-id:en-path:group-store group-id)
    %+  weld
      :~  (group-poke [%add-group group-id policy.act])
          (contact-poke [%create path])
          (contact-hook-poke [%add-owned path])
      ==
    (create-metadata path title.act description.act)
  ::
      %join
    =/  =path
      (group-id:en-path:group-store group-id.act)
    :~  (group-listen-hook-poke [%add group-id.act])
        (group-proxy-poke %add-members group-id.act (sy our.bol ~) ~)
        (contact-hook-poke [%add-synced ship.group-id.act path])
        (sync-metadata ship.group-id.act path)
    ==
  ::
      %invite
    =*  group-id  group-id.act
    =/  =path
      (group-id:en-path:group-store group-id)
    :~  (send-invite ship.group-id %groups path ship.act text.act)
        (add-pending group-id ship.act)
    ==
  ::
      %delete
    =/  =group-id
      (need (group-id:de-path:group-store path.act))
    %+  weld
    :~  (contact-hook-poke [%remove path.act])
        (group-poke [%remove-group group-id ~])
        (contact-poke [%delete path.act])
    ==
    (delete-metadata path.act)
  ::
      %remove
    =/  =group-id
      (need (group-id:de-path:group-store path.act))
    :~  (group-poke %remove-members group-id (sy ship.act ~))
        (contact-poke [%remove path.act ship.act])
    ==
  ::
      %share
    ::  determine whether to send to our contact-hook or foreign
    ::  send contact-action to contact-hook with %add action
    [(share-poke recipient.act [%add path.act ship.act contact.act])]~
  ==
++  poke-handle-http-request
  |=  =inbound-request:eyre
  ^-  simple-payload:http
  =+  url=(parse-request-line url.request.inbound-request)
  =/  name=@t
    =+  back-path=(flop site.url)
    ?~  back-path
      ''
    i.back-path
  ?+  site.url  not-found:gen
      [%'contact-view' @ *]
    =/  =path  (flop t.t.site.url)
    ?~  path  not-found:gen
    =/  contact  (contact-scry `^path`(snoc (flop t.path) name))
    ?~  contact  not-found:gen
    ?~  avatar.u.contact  not-found:gen
    ?-  -.u.avatar.u.contact
        %url   [[307 ['location' url.u.avatar.u.contact]~] ~]
        %octt
      =/  max-3-days  ['cache-control' 'max-age=259200']
      =/  content-type  ['content-type' content-type.u.avatar.u.contact]
      [[200 [content-type max-3-days ~]] `octs.u.avatar.u.contact]
    ==
  ==
::
::  +utilities
::
++  add-pending
  |=  [=group-id =ship]
  ^-  card
  =/  app=term
    ?:  =(our.bol ship.group-id)
      %group-store
    %group-hook
  =/  =cage
    :-  %group-action
    !>  ^-  action:group-store
    [%change-policy group-id %add-invites (sy ship ~)]
  [%pass / %agent [ship.group-id app] %poke cage]
++  send-invite
  |=  =invite
  ^-  card
  =/  =cage
    :-  %invite-action
    !>  ^-  invite-action
    [%invite /groups (shaf %invite-uid eny.bol) invite]
  [%pass / %agent [recipient.invite %invite-hook] %poke cage]
++  contact-poke
  |=  act=contact-action
  ^-  card
   [%pass / %agent [our.bol %contact-store] %poke %contact-action !>(act)]
::
++  contact-hook-poke
  |=  act=contact-hook-action
  ^-  card
  [%pass / %agent [our.bol %contact-hook] %poke %contact-hook-action !>(act)]
::
++  share-poke
  |=  [=ship act=contact-action]
  ^-  card
  [%pass / %agent [ship %contact-hook] %poke %contact-action !>(act)]
::
++  group-poke
  |=  act=action:group-store
  ^-  card
  [%pass / %agent [our.bol %group-store] %poke %group-action !>(act)]
::
++  group-proxy-poke
  |=  act=action:group-store
  ^-  card
  [%pass / %agent [ship.group-id.act %group-hook] %poke %group-action !>(act)]
::
++  group-listen-hook-poke
  |=  act=action:group-hook
  ^-  card
  [%pass / %agent [our.bol %group-hook] %poke %group-hook-action !>(act)]
::
++  metadata-poke
  |=  act=metadata-action
  ^-  card
  [%pass / %agent [our.bol %metadata-store] %poke %metadata-action !>(act)]
::
++  metadata-hook-poke
  |=  act=metadata-hook-action
  ^-  card
  [%pass / %agent [our.bol %metadata-hook] %poke %metadata-hook-action !>(act)]
::
++  perm-group-hook-poke
  |=  act=permission-group-hook-action
  ^-  card
  :*  %pass  /  %agent  [our.bol %permission-group-hook]
      %poke  %permission-group-hook-action  !>(act)
  ==
::
++  permission-hook-poke
  |=  act=permission-hook-action
  ^-  card
  :*  %pass  /  %agent  [our.bol %permission-hook]
      %poke  %permission-hook-action  !>(act)
  ==
::
++  sync-metadata
  |=  [=ship =path]
  ^-  card
  (metadata-hook-poke %add-synced ship path)
::
++  create-metadata
  |=  [=path title=@t description=@t]
  ^-  (list card)
  =/  =metadata
    %*  .  *metadata
        title         title
        description   description
        date-created  now.bol
        creator       our.bol
    ==
  :~  (metadata-poke [%add path [%contacts path] metadata])
      (metadata-hook-poke [%add-owned path])
  ==
::
++  delete-metadata
  |=  =path
  ^-  (list card)
  :~  (metadata-poke [%remove path [%contacts path]])
      (metadata-hook-poke [%remove path])
  ==
::
++  all-scry
  ^-  rolodex
  .^(rolodex %gx /=contact-store/(scot %da now.bol)/all/noun)
::
++  contact-scry
  |=  pax=path
  ^-  (unit contact)
  =.  pax  ;:(weld /=contact-store/(scot %da now.bol)/contact pax /noun)
  .^((unit contact) %gx pax)
--
