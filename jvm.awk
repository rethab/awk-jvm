function bail(msg) {
  print "Error: " msg
  exit
}

function ensure(b, ex, offset) {
  if (b != strtonum(ex)) {
    bail("Expected " ex " but got " b " at offset " offset)
  }
}

function read_magic() {
  x = strtonum($IX); ensure(x, "0xCA", IX); IX++;
  x = strtonum($IX); ensure(x, "0xFE", IX); IX++;
  x = strtonum($IX); ensure(x, "0xBA", IX); IX++;
  x = strtonum($IX); ensure(x, "0xBE", IX); IX++;
}

function read_const_pool(    count, i, tag, len, str, y) {
  count = read_u2();
  for (i = 1; i < count; i++) {
    tag = read_u1();
    CP[i]["tag"] = tag;
    if (tag == 1) {
      # string literal
      len = read_u2();
      str = "";
      for (y = 0; y < len; y++) {
        str = str sprintf("%c", $(y+IX));
      }
      IX += len;
      CP[i]["string"] = str;
    } else if (tag == 3) { # constant integer
      CP[i]["bytes"] = read_i4();
    } else if (tag == 7) { # class
      CP[i]["name_index"] = read_u2();
    } else if (tag == 8) { # string
      CP[i]["string_index"] = read_u2();
    } else if (tag == 9) { # fieldref
      CP[i]["class_index"] = read_u2();
      CP[i]["name_and_type_index"] = read_u2();
    } else if (tag == 10) { # methodref
      CP[i]["class_index"] = read_u2();
      CP[i]["name_and_type_index"] = read_u2();
    } else if (tag == 12) { # name and type
      CP[i]["name_index"] = read_u2();
      CP[i]["descriptor_index"] = read_u2();
    } else {
      bail("Unhandled tag " tag);
    }
  }

}

function read_cp_string(idx) {
  if      (CP[idx]["tag"] ==  1) return CP[idx]["string"];
  else if (CP[idx]["tag"] ==  7) return read_cp_string(CP[idx]["name_index"]);
  else if (CP[idx]["tag"] ==  8) return read_cp_string(CP[idx]["string_index"]);
  else if (CP[idx]["tag"] ==  9) return read_cp_string(CP[idx]["name_and_type_index"]);
  else if (CP[idx]["tag"] == 10) return read_cp_string(CP[idx]["name_and_type_index"]);
  else if (CP[idx]["tag"] == 12) return read_cp_string(CP[idx]["name_index"]);
  else bail("Unhandled tag in read_cp_string (" idx ") " CP[idx]["tag"])
}

function read_cp_descriptor(idx) {
  if      (CP[idx]["tag"] ==  1) return CP[idx]["string"];
  else if (CP[idx]["tag"] == 10) return read_cp_descriptor(CP[idx]["name_and_type_index"]);
  else if (CP[idx]["tag"] == 12) return read_cp_descriptor(CP[idx]["descriptor_index"]);
  else bail("Unhandled tag in read_cp_string (" idx ") " CP[idx]["tag"])
}

function argc(idx,    cp_desc) {
  cp_desc = read_cp_descriptor(idx);
  return length(cp_desc) - 2 - (length(cp_desc) - index(cp_desc, ")"));
}

function read_interfaces(    count, i) {
  count = read_u2();
  for(i = 0; i < count; i++) {
    INTERFACES[i] = read_cp_string(read_u2());
  }
}

function read_attributes(atts,    count, i, n, y) {
  count = read_u2();
  for (i = 0; i < count; i++) {
    atts[i]["name"] = read_cp_string(read_u2());
    n = read_u4();
    for (y = 0; y < n; y++) {
      atts[i]["data"][y] = read_u1();
    }
  }
}

function read_fields(    count, i) {
  count = read_u2();
  if (count != 0) { bail("fields are not supported yet"); }
}

function read_methods(    i, count, y, j) {
  count = read_u2();
  for(i = 0; i < count; i++) {
    METHODS[i]["flags"] = read_u2();
    METHODS[i]["name"] = read_cp_string(read_u2());
    METHODS[i]["descriptor"] = read_cp_string(read_u2());
    read_attributes(atts);
    for (y in atts) {
      METHODS[i]["attributes"][y]["name"] = atts[y]["name"];
      for (j in atts[y]["data"]) {
        METHODS[i]["attributes"][y]["data"][j] = atts[y]["data"][j];
      }
    }
  }
}

function read_u1(    x) {
  x = strtonum($IX); IX++;
  return x;
}

function read_u2(    high, low) {
  high = strtonum($IX); IX++;
  low  = strtonum($IX); IX++;
  return or(lshift(high, 8), low);
}

function read_u4(    high, low) {
  high = read_u2();
  low  = read_u2();
  return or(lshift(high, 16), low);
}

function read_i4(    x) {
  x = read_u4();
  if (and(x, 0x80000000) == 0x80000000) {
    # and is required because the compl might work with 64bits (unintmax_t)
    return -1 * (and(0xFFFFFFFF, compl(x)) + 1);
  } else {
    return x;
  }
}

function run_frame(name, locals,    m, a, d, c, frame, op, stack, sp, newlocals, _argc) {
  for (m in METHODS) {
    if (METHODS[m]["name"] == name) {
      for (a in METHODS[m]["attributes"]) {
        if (METHODS[m]["attributes"][a]["name"] == "Code") {
          frame["maxstack"]  = lshift(METHODS[m]["attributes"][a]["data"][0], 8);
          frame["maxstack"] += METHODS[m]["attributes"][a]["data"][1];
          frame["maxlocals"]  = lshift(METHODS[m]["attributes"][a]["data"][2], 8);
          frame["maxlocals"] += METHODS[m]["attributes"][a]["data"][3];
          frame["codelength"]  = lshift(METHODS[m]["attributes"][a]["data"][4], 24);
          frame["codelength"] += lshift(METHODS[m]["attributes"][a]["data"][5], 16);
          frame["codelength"] += lshift(METHODS[m]["attributes"][a]["data"][6], 8);
          frame["codelength"] += METHODS[m]["attributes"][a]["data"][7];
          for (d = 8; d < frame["codelength"] + 8; d++) {
            frame["code"][d-8] = METHODS[m]["attributes"][a]["data"][d];
          }
          for (d = 0; d < frame["maxlocals"]; d++) {
            frame["locals"][d] = locals[d];
          }
          break;
        }
      }
    }
  }

  if (typeof(frame["code"]) != "array") {
    bail("Method " name " not found?");
  }

  sp = 0;
  c = 0;
  while (c < length(frame["code"])) {
    op = frame["code"][c];

    if (op == 2) { # iconst_m1
      stack[sp++] = -1;
    } else if (op == 3) { # iconst_0
      stack[sp++] = 0;
    } else if (op == 4) { # iconst_1
      stack[sp++] = 1;
    } else if (op == 5) { # iconst_2
      stack[sp++] = 2;
    } else if (op == 6) { # iconst_3
      stack[sp++] = 3;
    } else if (op == 7) { # iconst_4
      stack[sp++] = 4;
    } else if (op == 8) { # iconst_5
      stack[sp++] = 5;
    } else if (op == 16) { # bipush
      stack[sp++] = strtonum(frame["code"][++c]);
    } else if (op == 17) { # sipush
      _h = strtonum(frame["code"][++c]);
      _l = strtonum(frame["code"][++c]);
      stack[sp++] = or(_l, lshift(_h, 8));
    } else if (op == 18) { # ldc
      _ix = strtonum(frame["code"][++c]);
      stack[sp++] = CP[_ix]["bytes"]
    } else if (op == 26) { # iload_0
      stack[sp++] = frame["locals"][0];
    } else if (op == 27) { # iload_1
      stack[sp++] = frame["locals"][1];
    } else if (op == 59) { # istore_0
      frame["locals"][0] = stack[--sp];
    } else if (op == 60) { # istore_1
      frame["locals"][1] = stack[--sp];
    } else if (op == 61) { # istore_2
      frame["locals"][2] = stack[--sp];
    } else if (op == 62) { # istore_3
      frame["locals"][3] = stack[--sp];
    } else if (op == 96) { # iadd
      a = stack[--sp];
      b = stack[--sp];
      stack[sp++] = a + b;
    } else if (op == 100) { # isub
      a = stack[--sp];
      b = stack[--sp];
      stack[sp++] = a - b;
    } else if (op == 172) { # ireturn
      return stack[--sp]
    } else if (op == 184) { # invokestatic
      indexbyte1 = strtonum(frame["code"][++c]);
      indexbyte2 = strtonum(frame["code"][++c]);
      _ix = or(lshift(indexbyte1, 8), indexbyte2);
      _mname = read_cp_string(_ix);
      _argc = argc(_ix);
      _ix = 0;
      while (_ix < _argc) {
        newlocals[_ix++] = stack[--sp];
      }
      _res = run_frame(_mname, newlocals);
      stack[sp++] = _res;
    } else {
      bail("Unhandled op " op);
    }
    c++;
  }
}

{
  IX = 1;

  read_magic()
  minor = read_u2();
  major = read_u2();
  read_const_pool();
  flags = read_u2(); # access flags
  thisname = read_cp_string(read_u2());
  supername = read_cp_string(read_u2());
  read_interfaces();
  read_fields();
  read_methods();
  read_attributes(atts);

  print run_frame("main", locals);
}
