$(document).ready(start);

/**
 * запускаем функцию получения сообщений
 */
function start(){
    $.ajax({
        type: 'POST',
        url: 'sendmail.pl',
        data: 'action=startsession',
        success: function(data){
            var div   = document.getElementById('capcha'),
                no    = data == 0 ? "" : "[не]";
                capch = "Я "+no+" бот! - Это правда?";
            div.innerHTML = capch;
        }
    });
}

function sendMessage(){

    var login   = document.getElementById('login').value,
        message = document.getElementById('message').value,
        email   = document.getElementById('email').value,
        cap     = document.getElementById('cap'),
        capcha  = "0";
        if(cap.checked == true){capcha = "1"};
    if((login == '')){
        alert("вы не ввели тему сообщения");
        return;
    }

    if(message == ''){
        alert('Вы не ввели сообщение');
        return;
    }

    if(email == ''  || !validateEmail(email)){
        alert('Неверный e-mail адрес');
        return;
    }

    if(message != '' && login != '' && email != ''){
        $.ajax({
            type: 'POST',
            url: 'sendmail.pl',
            data: 'action=sendMessage&login='+login+"&message="+message+"&email="+email+"&capcha="+capcha,
            success: function(data){
                if(data == 'error'){
                    alert('Ваше сообщение не доставленно');
                }else if(data == 'OK'){
                    alert('Ваше сообщение доставленно');
                }
                document.getElementById('login').value   = "";
                document.getElementById('message').value = "";
                document.getElementById('email').value   = "";
                setTimeout(function(){location.href = "./"},2000);
            }
        });
    }
}

function validateEmail(email) {
    var re = /^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
    return re.test(email);
}


function validate(e, _this) {
    var keynum, keychar, rexp, strVal, subStr, pos;
    //создаем обьект с регулярными выражениями
    var regexp = {};

    regexp.login = new RegExp("[^A-Za-zА-я0-9\\_\\-]", "gim");
    regexp.email = new RegExp("[^A-Za-z0-9\\_\\-\.\@]", "gim");

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
