-module(oauth_hmac).

-export([signature/3]).

% for testing:
-export([base_string/3]).
-export([normalize/1]).


signature({Method, URL, Params}, ConsumerSecret, TokenSecret) ->
  signature(base_string(Method, URL, Params), ConsumerSecret, TokenSecret);
signature(BaseString, ConsumerSecret, TokenSecret) ->
  b64(crypto:sha_mac(key(ConsumerSecret, TokenSecret), BaseString)).

base_string(Method, URL, Params) when is_list(Method) ->
  string:join(lists:map(fun fmt:percent_encode/1, [Method, uri_normalize(URL), normalize(Params)]), "&").

normalize(Params) ->
  StringParams = lists:map(fun({K, V}) when is_atom(K) -> {atom_to_list(K), V}; (I) -> I end, Params),
  oauth_params:to_string(sort(StringParams)).

uri_normalize(URL) ->
  case http_uri:parse(URL) of
    {error, _Reason} ->
      URL;
    Parts ->
      oauth_util:uri_join(Parts)
  end.

sort(Params) ->
  lists:sort(fun({K,X},{K,Y}) -> X < Y; ({A,_},{B,_}) -> A < B end, Params).

key(ConsumerSecret, TokenSecret) ->
  fmt:sprintf("%s&%s", [fmt:percent_encode(ConsumerSecret), fmt:percent_encode(TokenSecret)]).

b64(Data) ->
  base64:encode_to_string(Data).
