import lldb
import traceback

def btlua_impl(debugger, command, result, internal_dict):
    try:
        target = debugger.GetSelectedTarget()
        process = target.GetProcess()
        thread = process.GetSelectedThread()
        frame = thread.GetSelectedFrame()

        # 解析输入参数
        args = command.split()
        if len(args) != 1:
            result.AppendMessage("Usage: btlua <lua_state_address>")
            return

        lua_state_addr = int(args[0], 16)
        L = frame.EvaluateExpression(f"(lua_State *){lua_state_addr}")
        if L.GetError().Fail():
            result.SetError(f"Invalid lua_State* address: {L.GetError()}")
            return

        # 获取 ci 指针
        p = L.GetChildMemberWithName("ci")
        if not p.IsValid():
            result.SetError("Failed to get L->ci")
            return
        
        stack = L.GetChildMemberWithName("stack")

        while p.GetValueAsUnsigned() != 0:
            # 获取 func 成员
            func = p.GetChildMemberWithName("func")
            if not func.IsValid():
                result.AppendMessage(f"0x{p.GetValueAsUnsigned():x} [ERROR: Invalid func]")
                continue

            result.AppendMessage(f"stack idx [{(func.GetValueAsUnsigned() - stack.GetValueAsUnsigned())//16}]")
            # 获取 tt_ 类型标记
            tt = func.GetChildMemberWithName("tt_").GetValueAsUnsigned() & 0x3f
            if tt == 0x06:  # LUA FUNCTION
                # 解析 Proto 结构
                gc = func.GetChildMemberWithName("value_").GetChildMemberWithName("gc").GetValueAsUnsigned()
                proto = frame.EvaluateExpression(f"((Closure *)({gc}))->l->p")
                if proto.GetError().Fail():
                    result.SetError(f"Invalid gcu* address: {proto.GetError()}")
                    return

                if not proto.IsValid():
                    break

                # 获取文件名和行号
                source = proto.GetChildMemberWithName("source")
                filename_addr = source.GetValueAsUnsigned() + 32  # 假设 source 是 char[32] 后的字符串
                error = lldb.SBError()
                filename = process.ReadCStringFromMemory(filename_addr, 256, error)
                if error.Fail():
                    filename = "<unknown>"

                lineno = proto.GetChildMemberWithName("linedefined").GetValueAsUnsigned()
                result.AppendMessage(f"0x{p.GetValueAsUnsigned():x} LUA FUNCTION {filename}:{lineno}")

            elif tt == 0x16:  # LIGHT C FUNCTION
                # 获取 C 函数指针
                f_ptr = func.GetChildMemberWithName("value_").GetChildMemberWithName("f").GetValueAsUnsigned()
                result.AppendMessage(f"0x{p.GetValueAsUnsigned():x} LIGHT C FUNCTION @ 0x{f_ptr:x}")

            elif tt == 0x26:  # C FUNCTION
                # 解析 C 闭包
                gc = func.GetChildMemberWithName("value_").GetChildMemberWithName("gc").GetValueAsUnsigned()
                f_ptr = frame.EvaluateExpression(f"((Closure *)({gc}))->c->f")
                if f_ptr.GetError().Fail():
                    result.SetError(f"Invalid f_ptr* address: {f_ptr.GetError()}")

                result.AppendMessage(f"0x{p.GetValueAsUnsigned():x} C FUNCTION @ {f_ptr}")

            else:  # BASE
                result.AppendMessage(f"0x{p.GetValueAsUnsigned():x} LUA BASE")

            # 移动到 previous
            p = p.GetChildMemberWithName("previous")
            if not p.IsValid():
                break

    except Exception as e:
        error_message = f"Script error: {str(e)}\n{traceback.format_exc()}"
        result.SetError(error_message)

def __lldb_init_module(debugger, internal_dict):
    debugger.HandleCommand('command script clear')
    debugger.HandleCommand('command script add -f btlua.btlua_impl btlua')
