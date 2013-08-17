$(document).ready(getcontent(1));

/**
 * следующий коментарий
 */
function nextquote(){
    var id = document.getElementById('hid').value;
    id++;

    getcontent(id, 'nextcoment');
}

/**
 * предыдущий коментарий
 */
function prev_quote(){
    var id = document.getElementById('hid').value;
    id--;
    if(id < 1){
        alert('это самый первый коментарий');
    }else{
        getcontent(id, 'prevcoment');
    }
}

/**
 * запускаем функцию получения сообщений
 */
function getcontent(per, action){
    $.ajax({
        type: 'POST',
        url: 'pars.pl',
        dataType: 'json',
        data: 'action='+action+'&id='+per,
        success: function(data){
            var text = data['content'],
                hid = data['id']+"<input type=\"hidden\" value=\""+data['id']+"\" id=\"hid\">";

            //нежно перематываем цитаты
            $('#id').animate({'opacity':0}, 500, function(){
                $('#id').html(hid);
                $('#id').animate({'opacity':1}, 500);});

            $('#content').animate({'opacity':0}, 500, function(){
                $('#content').html(text);
                $('#content').animate({'opacity':1}, 500);});

        }
    });
}

