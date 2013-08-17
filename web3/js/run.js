function goenable(){
    var login = document.getElementById('login').value,
        pass  = document.getElementById('pass').value;

    if(login == '' || pass == ''){
        $('#goauth').attr("disabled","disabled");
    }else if(login != '' && pass != ''){
        $('#goauth').removeAttr("disabled");
    };
}


function validate(e, _this) {
    goenable();
    var keynum, keychar, rexp, strVal, subStr, pos;
    //создаем обьект с регулярными выражениями
    var regexp = {};

    regexp.login = new RegExp("[^A-Za-zА-я0-9\\_\\-]", "gim");
    regexp.pass = new RegExp("[^A-Za-z0-9\\_\\-\.\]", "gim");

    if(window.event)
        keynum = e.keyCode;
    else if(e.which)
        keynum = e.which;

    //заглушка на клавиши Left, Right, Up, Down, Tab, Del, Backspace
    if( ((e.keyCode >= 35 && e.keyCode <= 40 || e.keyCode == 46) && e.which == 0) || e.keyCode == 9 || e.keyCode == 8)
        return true;
    keychar = String.fromCharCode(keynum);
    rexp = regexp[_this.name];

    //обработчик для события keyup, blur
    if(e.type=='keyup' || e.type=='blur')
    {
        if(rexp.test(_this.value))
        {
            _this.value = _this.value.replace(rexp,'');
            return true;
        }
        else return false;
    }
    pos    = getCaret(_this);//позиция каретки
    subStr = _this.value.substr(0, pos);
    strVal = _this.value.replace(subStr, subStr + keychar);

    return !rexp.test(strVal);
}
