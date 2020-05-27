::  chat-view: sets up chat JS client, paginates data, and combines commands
::  into semantic actions for the UI
::
/-  *permission-store,
    *permission-hook,
    *group,
    *invite-store,
    *metadata-store,
    group-hook,
    *permission-group-hook,
    *chat-hook,
    *metadata-hook,
    contact-view
/+  *server, *chat-json, default-agent, verb, dbug, group-store, grpl=group
::
~%  %chat-view-top  ..is  ~
|%
+$  card  card:agent:gall
::
+$  poke
  $%  [%chat-action chat-action]
      [%group-action action:group-store]
      [%chat-hook-action chat-hook-action]
      [%permission-hook-action permission-hook-action]
      [%permission-group-hook-action permission-group-hook-action]
  ==
--
%+  verb  |
%-  agent:dbug
^-  agent:gall
=<
  ~%  %chat-view-agent-core  ..poke-handle-http-request  ~
  |_  bol=bowl:gall
  +*  this       .
      chat-core  +>
      cc         ~(. chat-core bol)
      def        ~(. (default-agent this %|) bol)
  ::
  ++  on-init
    ^-  (quip card _this)
    :_  this
    [%pass /updates %agent [our.bol %chat-store] %watch /updates]~
  ::
  ++  on-poke
    ~/  %chat-view-poke
    |=  [=mark =vase]
    ^-  (quip card _this)
    ?>  (team:title our.bol src.bol)
    ?+    mark  (on-poke:def mark vase)
        %handle-http-request
      =+  !<([eyre-id=@ta =inbound-request:eyre] vase)
      :_  this
      %+  give-simple-payload:app  eyre-id
      %+  require-authorization:app  inbound-request
      poke-handle-http-request:cc
    ::
        %json
      :_  this
      (poke-chat-view-action:cc (json-to-view-action !<(json vase)))
    ::
        %chat-view-action
      :_  this
      (poke-chat-view-action:cc !<(chat-view-action vase))
    ==
  ::
  ++  on-watch
    ~/  %chat-view-watch
    |=  =path
    ^-  (quip card _this)
    ?>  (team:title our.bol src.bol)
    |^
    ?:  ?=([%http-response *] path)
      [~ this]
    ?:  =(/primary path)
      ::  create inbox with 20 messages max per mailbox and send that along
      ::  then quit the subscription
      :_  this
      [%give %fact ~ %json !>((inbox-to-json truncated-inbox-scry))]~
    ?:  =(/configs path)
      [[%give %fact ~ %json !>(*json)]~ this]
    (on-watch:def path)
    ::
    ++  message-limit  20
    ::
    ++  truncated-inbox-scry
      ^-  inbox
      =/  =inbox  .^(inbox %gx /=chat-store/(scot %da now.bol)/all/noun)
      %-  ~(run by inbox)
      |=  =mailbox
      ^-  ^mailbox
      [config.mailbox (scag message-limit envelopes.mailbox)]
    --
  ::
  ++  on-agent
    ~/  %chat-view-agent
    |=  [=wire =sign:agent:gall]
    ^-  (quip card _this)
    ?+    -.sign  (on-agent:def wire sign)
        %kick
      :_  this
      [%pass / %agent [our.bol %chat-store] %watch /updates]~
    ::
        %fact
      ?+  p.cage.sign  (on-agent:def wire sign)
          %chat-update
        :_  this
        (diff-chat-update:cc !<(chat-update q.cage.sign))
      ==
    ==
  ::
  ++  on-arvo
    ~/  %chat-view-arvo
    |=  [=wire =sign-arvo]
    ^-  (quip card _this)
    ?.  ?=(%bound +<.sign-arvo)
      (on-arvo:def wire sign-arvo)
    [~ this]
  ::
  ++  on-save  on-save:def
  ++  on-load  
    |=  old=*
    ^-  (quip card _this)
    :_  this
    :~  [%pass / %arvo %e %disconnect [~ /'~chat']]
        [%pass / %arvo %e %connect [~ /'chat-view'] %chat-view]
    ==
  ::
  ++  on-leave  on-leave:def
  ++  on-peek   on-peek:def
  ++  on-fail   on-fail:def
  --
::
::
~%  %chat-view-library  ..card  ~
|_  bol=bowl:gall
++  grp  ~(. grpl bol)
::
++  poke-handle-http-request
  |=  =inbound-request:eyre
  ^-  simple-payload:http
  =+  url=(parse-request-line url.request.inbound-request)
  ?+  site.url  not-found:gen
      [%'chat-view' %paginate @t @t *]
    =/  start  (need (rush i.t.t.site.url dem))
    =/  end  (need (rush i.t.t.t.site.url dem))
    =/  pax  t.t.t.t.site.url
    =/  envelopes  (envelope-scry [(scot %ud start) (scot %ud end) pax])
    %-  json-response:gen
    %-  json-to-octs
    %-  update-to-json
    [%messages pax start end envelopes]
  ==
::
++  poke-json
  |=  jon=json
  ^-  (list card)
  ?>  (team:title our.bol src.bol)
  (poke-chat-view-action (json-to-view-action jon))
::
++  poke-chat-view-action
  |=  act=chat-view-action
  ^-  (list card)
  |^
  ?>  (team:title our.bol src.bol)
  ?-  -.act
      %create
    ?>  ?=(^ app-path.act)
    ?>  |(=(group-path.act app-path.act) =(~(tap in members.act) ~))
    ?^  (chat-scry app-path.act)
      ~&  %chat-already-exists
      ~
    %-  zing
    :~  (create-chat app-path.act allow-history.act)
        %-  create-group
        :*  group-path.act
            app-path.act
            policy.act
            members.act
            title.act
            description.act
        ==
        (create-metadata title.act description.act group-path.act app-path.act)
    ==
  ::
      %delete
    ?>  ?=(^ app-path.act)
    ::  always just delete the chat from chat-store
    ::
    :+  (chat-hook-poke [%remove app-path.act])
      (chat-poke [%delete app-path.act])
    ::  if we still have metadata for the chat, remove it, and the associated
    ::  group if it's unmanaged
    ::
    ::    we aren't guaranteed to have metadata: the chat might have been
    ::    deleted by the host, which pushes metadata deletion down to us.
    ::
    =/  group=path
      (group-from-chat app-path.act)
    =/  =group-id
      (need (group-id:de-path:group-store group))
    %-  zing
    :~  ?.  (is-creator group %chat app-path.act)  ~
        [(metadata-poke [%remove group [%chat app-path.act]])]~
      ::
        :~  (group-proxy-poke %remove-members group-id (sy our.bol ~))
            (group-poke [%remove-group group-id ~])
            (metadata-hook-poke [%remove group])
            (metadata-store-poke [%remove group [%chat app-path.act]])
        ==
    ==
  ::
      %join
    ::  joining unmanaged chat if we don't have the group already
    =/  group-path
      (fall (maybe-group-from-chat app-path.act) app-path.act)
    =/  =group-id
      (need (group-id:de-path:group-store group-path))
    :~  (group-proxy-poke %add-members group-id (sy our.bol ~) ~)
        (group-hook-poke %add group-id)
        (chat-hook-poke [%add-synced ship.act app-path.act ask-history.act])
        (metadata-hook-poke [%add-synced ship.act group-path])
    ==
  ::
      %groupify
    =*  app-path  app-path.act
    =/  scry-pax=path
      /metadata/[(scot %t (spat app-path))]/chat/[(scot %t (spat app-path))]
    =/  =metadata
      (need (scry-for (unit metadata) %metadata-store scry-pax))
    =/  old-group-id=group-id
      (need (group-id:de-path:group-store app-path))
    ?<  (is-managed:grp old-group-id)
    ?~  existing.act
      ::  just create contacts object for group
      ~[(contact-view-poke %groupify old-group-id title.metadata description.metadata)]
    ::  change associations
    =*  group-path  group-path.u.existing.act
    =/  =group-id
      (need (group-id:de-path:group-store group-path))
    =/  old-group=group
      (need (scry-group:grp old-group-id))
    =/  =group
      (need (scry-group:grp group-id))
    =/  ships=(set ship)
      (~(dif in members.old-group) members.group)
    ~&  ships
    ~&  group
    ~&  old-group
    :*  (metadata-store-poke %remove app-path %chat app-path)
        (metadata-store-poke %add group-path [%chat app-path] metadata)
        (group-poke %remove-group old-group-id ~)
        ?.  inclusive.u.existing.act
          ~
        :-  (group-poke %add-members group-id ships ~)
        %+  turn
          ~(tap in ships)
        |=  =ship
        (send-invite group-path app-path ship)
    ==
  ==
  ::
  ++  create-chat
    |=  [=path history=?]
    ^-  (list card)
    :~  (chat-poke [%create path])
        (chat-hook-poke [%add-owned path history])
    ==
  ::
  ++  create-group
    |=  [=path app-path=path =policy ships=(set ship) title=@t desc=@t]
    ^-  (list card)
    ?^  (group-scry path)  ~
    =/  =group-id
      (need (group-id:de-path:group-store path))
    ?>  =(our.bol ship.group-id)
    ::  do not create a contacts object if this is unmanaged
    ::
    :-
      ?:  =(path app-path)
        (group-poke %add-group group-id policy)
      (contact-view-poke %create term.group-id policy title desc)
    %+  murn  ~(tap in ships)
    |=  =ship
    ^-  (unit card)
    ?:  =(ship our.bol)  ~
    `(send-invite path app-path ship)
  ::
  ++  create-metadata
    |=  [title=@t description=@t group-path=path app-path=path]
    ^-  (list card)
    =/  =metadata
      %*  .  *metadata
          title         title
          description   description
          date-created  now.bol
          creator
        %+  slav  %p
        ?:  (is-managed app-path)  (snag 0 app-path)
        (snag 1 app-path)
      ==
    :~  (metadata-poke [%add group-path [%chat app-path] metadata])
        (metadata-hook-poke [%add-owned group-path])
    ==
  ::
  ++  contact-view-poke
    |=  act=contact-view-action:contact-view
    ^-  card
    [%pass / %agent [our.bol %contact-view] %poke %contact-view-action !>(act)]
  ::
  ++  metadata-poke
    |=  act=metadata-action
    ^-  card
    [%pass / %agent [our.bol %metadata-hook] %poke %metadata-action !>(act)]
  ::
  ++  metadata-store-poke
    |=  act=metadata-action
    ^-  card
    [%pass / %agent [our.bol %metadata-store] %poke %metadata-action !>(act)]
  ::
  ++  metadata-hook-poke
    |=  act=metadata-hook-action
    ^-  card
    :*  %pass  /  %agent
        [our.bol %metadata-hook]
        %poke  %metadata-hook-action
        !>(act)
    ==
  ::
  ++  send-invite
    |=  [group-path=path app-path=path =ship]
    ^-  card
    =/  managed=?
      !=(app-path group-path)
    =/  =invite
      :*  our.bol
          ?:(managed %contact-hook %chat-hook)
          ?:(managed group-path app-path)
          ship  ''
      ==
    =/  act=invite-action  [%invite ?:(managed /contacts /chat) (shaf %msg-uid eny.bol) invite]
    [%pass / %agent [our.bol %invite-hook] %poke %invite-action !>(act)]
  ::
  ++  chat-scry
    |=  pax=path
    ^-  (unit mailbox)
    =.  pax  ;:(weld /=chat-store/(scot %da now.bol)/mailbox pax /noun)
    .^((unit mailbox) %gx pax)
  ::
  ++  maybe-group-from-chat
    |=  app-path=path
    ^-  (unit path)
    ?.  .^(? %gu (scot %p our.bol) %metadata-store (scot %da now.bol) ~)
      ?:  ?=([@ ^] app-path)
        ~&  [%assuming-ported-legacy-chat app-path]
        `[%'~' app-path]
      ~&  [%weird-chat app-path]
      !!
    =/  resource-indices
      .^  (jug resource group-path)
        %gy
        (scot %p our.bol)
        %metadata-store
        (scot %da now.bol)
        /resource-indices
      ==
    =/  groups=(set path)
      %+  fall
        (~(get by resource-indices) [%chat app-path])
      *(set path)
    ?~  groups  ~
    `n.groups
  ::
  ++  group-from-chat
    (cork maybe-group-from-chat need)
  ::
  ++  is-managed
    |=  =path
    ^-  ?
    ?>  ?=(^ path)
    !=(i.path '~')
  ::
  ++  is-creator
    |=  [group-path=path app-name=@ta app-path=path]
    ^-  ?
    =/  meta=(unit metadata)
      .^  (unit metadata)
        %gx
        (scot %p our.bol)
        %metadata-store
        (scot %da now.bol)
        %metadata
        (scot %t (spat group-path))
        app-name
        (scot %t (spat app-path))
        /noun
      ==
    ?~  meta  !!
    =(our.bol creator.u.meta)
  --
::
++  diff-chat-update
  |=  upd=chat-update
  ^-  (list card)
  =/  updates-json  (update-to-json upd)
  =/  configs-json  (configs-to-json configs-scry)
  :~  [%give %fact ~[/primary] %json !>(updates-json)]
      [%give %fact ~[/configs] %json !>(configs-json)]
  ==
::
::  +utilities
::
++  chat-poke
  |=  act=chat-action
  ^-  card
  [%pass / %agent [our.bol %chat-store] %poke %chat-action !>(act)]
::
++  group-poke
  |=  act=action:group-store
  ^-  card
  [%pass / %agent [our.bol %group-store] %poke %group-action !>(act)]
++  group-hook-poke
  |=  act=action:group-hook
  ^-  card
  [%pass / %agent [our.bol %group-hook] %poke %group-hook-action !>(act)]
::
++  group-proxy-poke
  |=  act=action:group-store
  ^-  card
  [%pass / %agent [ship.group-id.act %group-hook] %poke %group-action !>(act)]
::
++  permission-poke
  |=  act=permission-action
  ^-  card
  [%pass / %agent [our.bol %permission-store] %poke %permission-action !>(act)]
::
++  chat-hook-poke
  |=  act=chat-hook-action
  ^-  card
  [%pass / %agent [our.bol %chat-hook] %poke %chat-hook-action !>(act)]
::
++  permission-hook-poke
  |=  act=permission-hook-action
  ^-  card
  :*  %pass  /  %agent  [our.bol %permission-hook]
      %poke  %permission-hook-action  !>(act)
  ==
::
++  perm-group-hook-poke
  |=  act=permission-group-hook-action
  ^-  card
  :*  %pass  /  %agent  [our.bol %permission-group-hook]
      %poke  %permission-group-hook-action  !>(act)
  ==
::
++  envelope-scry
  |=  pax=path
  ^-  (list envelope)
  (scry-for (list envelope) %chat-store [%envelopes pax])
::
++  configs-scry
  ^-  chat-configs
  (scry-for chat-configs %chat-store /configs)
::
++  group-scry
  |=  pax=path
  ^-  (unit group)
  (scry-for (unit group) %group-store [%groups pax])
::
++  scry-for
  |*  [=mold app=term =path]
  .^  mold
    %gx
    (scot %p our.bol)
    app
    (scot %da now.bol)
    (snoc `^path`path %noun)
  ==
--
