define btlua
  if $argc != 0
    printf "Usage: btlua <lua_state_address>\n"
  end
  set $L = (lua_State*)$arg0
  set $p = $L.ci
  while ( $p != 0 )
    set $o = ($p.func)
    set $tt = ( $o.tt_ & 0x3f )
    if ( $tt == 0x06 )
      set $gcu = ((union GCUnion*)($p.func.value_.gc))
      set $proto = $gcu.cl.l.p
      set $source = $proto.source
      set $filename = (char*)($source) + 32
      set $lineno = ((union GCUnion*)($p.func.value_.gc)).cl.l.p.linedefined
      printf "0x%x LUA FUNCTION %s : %4d\n", $p, $filename, $lineno

      set $p = $p.previous
      loop_continue
    end

    if ( $tt == 0x16 )
      printf "0x%x LIGHT C FUNCTION" , $p
      output $p.func.value_.f
      printf " \n "

      set $p = $p.previous
      loop_continue
    end

    if ( $tt == 0x26 )
      printf "0x%x C FUNCTION" , $p
      set $gcu = ((union GCUnion*)($p.func.value_.gc))
      output $gcu.cl.c.f
      printf "\n"

      set $p = $p.previous
      loop_continue
    end

    printf "0x%x LUA BASE\n" , $p
    set $p = $p.previous
  end
end

