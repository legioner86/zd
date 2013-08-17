$(document).ready(start);

/**
 * запускаем функцию получения сообщений
 */
function start(){
    getMessage();
    setInterval(getMessage, 5000);
}

/**
 * получаем сообщения и выводим их
 */
function getMessage(){

    var contenet = document.getElementById('wrap');

    $.ajax({
        type: 'POST',
        url: 'comingbook.pl',
        data: 'action=getlastmessage',
        dataType: 'json',
        success: function(data){

            if(data){
                var div = "";
                //собираем последне сообщения и придаем им форму

                for(var i = 0;i < data.length;i++){
                    div +=" <div class='messages'>"+
                    "<div class='span3 leftbord'>"+
                "<span class='icon-user'></span> "+data[i]['login_sender']+
                "</br> <span class='icon-map-marker'></span> "+data[i]['ip']+
                "</br> <span class='icon-time'></span> "+data[i]['add_date']+
                "</div>"+
                    "<div class='span7'>"+data[i]['message']+"</div>"+
                "</div>";
                }
                contenet.innerHTML = div;
            }
        }
    });
}

/**
 * отправляем сообщение на запись
 */
function sendMessage(){

    var login   = document.getElementById('login'),
        message = document.getElementById('message');

    if((login.value == '')){
        alert("вы не ввели свой логин");
    }

    if(message.value == ''){
        alert('Вы не ввели сообщение');
    }

    if(message.value != '' && login.value != ''){
        $.ajax({
            type: 'POST',
            url: 'comingbook.pl',
            data: 'action=sendMessage&login='+login.value+"&message="+message.value,
            success: function(data){

                if(data == 'error'){
                    alert('Ваше сообщение не доставленно');
                }
            }
        });
        getMessage();
    }
    login.value   = '';
    message.value = '';
}

/**
 * валидация данных при вводе в поле
 * @param e
 * @param _this
 * @returns {boolean}
 */
function validate(e, _this) {
    var keynum, keychar, rexp, strVal, subStr, pos;
    //создаем обьект с регулярными выражениями
    var regexp = {};

    regexp.login = new RegExp("[^A-Za-zА-я0-9\\_\\-]", "gim");

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
