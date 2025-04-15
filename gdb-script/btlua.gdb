define btlua
  if $argc != 0
    printf "Usage: btlua <lua_state_address>\n"
  end
  set $L = (lua_State*)$arg0
  set $p = $L.ci
  set $stack = $L.stack
  while ( $p != 0 )
    set $o = ($p.func)
    set $tt = ( $o.tt_ & 0x3f )
    printf "stack idx[%d]\t", $o - $stack
    if ( $tt == 0x06 )
      set $lcl = ((LClosure*)($o.value_))
      set $proto = $lcl.p
      set $source = $proto.source
      set $filename = (char*)($source) + 32
      set $lineno = $proto.linedefined
      printf "0x%p LUA FUNCTION %s:%d\n", $o, $filename, $lineno

      set $p = $p.previous
      loop_continue
    end

    if ( $tt == 0x16 )
      printf "0x%p LIGHT C FUNCTION 0x%p\n" , $o, $o.value_.f

      set $p = $p.previous
      loop_continue
    end

    if ( $tt == 0x26 )
      set $ccl = ((CClosure*)($o.value_))
      printf "0x%p C FUNCTION 0x%p\n" , $p, $ccl.f

      set $p = $p.previous
      loop_continue
    end

    printf "0x%p LUA BASE\n" , $p
    set $p = $p.previous
  end
end

