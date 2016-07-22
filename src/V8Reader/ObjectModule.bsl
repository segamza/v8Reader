﻿//==============================================================================================================================================
// ПЕРЕМЕННЫЕ МОДУЛЯ ОБЪЕКТА
//==============================================================================================================================================

Перем КоллекцияВременныхФайлов Экспорт;
Перем СоответствиеИдентификаторов Экспорт;

//==============================================================================================================================================
// ФУНКЦИИ ДЛЯ АНАЛИЗА УЗЛОВ ДОКУМЕНТА DOM, ПОЛУЧЕННОГО ИЗ ВНУТРЕННЕГО ФОРМАТА 1С из публикации http://infostart.ru/public/57431/ от tormozit
//==============================================================================================================================================

Функция СтрокаВнутрВХМЛТело(вхСтрока) Экспорт //изначально было предложено brix8x в комментариях к публикации http://infostart.ru/public/17139/
	
	//{ Получение одной длинной строки
	выхХМЛТело = СтрЗаменить(вхСтрока, СИМВОЛЫ.ПС, "#%");
	выхХМЛТело = СтрЗаменить(выхХМЛТело, СИМВОЛЫ.ВК, "#%");
	//}
	
	//{ Заменяем символы, критичные для XML
	// & на "&amp;"
	// < на "&lt;"
	// > на "&gt;"
	выхХМЛТело = СтрЗаменить(выхХМЛТело, "&", "&amp;");
	выхХМЛТело = СтрЗаменить(выхХМЛТело, "<", "&lt;");
	выхХМЛТело = СтрЗаменить(выхХМЛТело, ">", "&gt;");
	//}
	
	//{Решаем проблему с кавычками:
	выхХМЛТело = СтрЗаменить(выхХМЛТело, """""", "^$^$");
	выхХМЛТело = СтрЗаменить(выхХМЛТело, """", Символы.ПС + "^$");
	//}
	
	ТекстДок = Новый ТекстовыйДокумент;
	ТекстДок.УстановитьТекст(выхХМЛТело);
	новХМЛТелоДок = Новый ТекстовыйДокумент;
	Максимум = СтрЧислоСтрок(выхХМЛТело);
	
	//{Обрабатываем документ построчно:
	КавычкаОткрыта = Истина;
	Для НомерСтроки = 1 По Максимум Цикл
		КавычкаОткрыта = НЕ КавычкаОткрыта;
		СтрокаДляВыводаСостояния = "Построение XML:           ";
		выхСтрока = ТекстДок.ПолучитьСтроку(НомерСтроки);
		Если КавычкаОткрыта = Истина Тогда
			
			//{Решаем проблему с получением модуля в управляемой форме
			выхСтрока = СтрЗаменить(выхСтрока, "#%", Символы.ВК);
			//}
			
			новХМЛТелоДок.ДобавитьСтроку(выхСтрока);
			
			Продолжить;
			
		КонецЕсли;
		
		//{ Замена одинарных символов
		выхСтрока = СтрЗаменить(выхСтрока, ",", "</data><data>");
		выхСтрока = СтрЗаменить(выхСтрока, "{", "<elem><data>");
		выхСтрока = СтрЗаменить(выхСтрока, "}", "</data></elem>");
		//}
		
		новХМЛТелоДок.ДобавитьСтроку(выхСтрока);
		
	КонецЦикла;
	
	новХМЛТело = новХМЛТелоДок.ПолучитьТекст();
	//}
	
	//{ Восстановление кавычек
	новХМЛТело = СтрЗаменить(новХМЛТело, Символы.ПС + "^$", "^$");
	новХМЛТело = СтрЗаменить(новХМЛТело, "^$", """");
	новХМЛТело = СтрЗаменить(новХМЛТело, "#%", "");
	//}
	
	//{ Удаление лишних блоков
	новХМЛТело = СтрЗаменить(новХМЛТело, "<data><elem>", "<elem>");
	новХМЛТело = СтрЗаменить(новХМЛТело, "</elem></data>", "</elem>");
	//}
	
	//{ Добавление переносов строк для удобства поиска различий
	новХМЛТело = СтрЗаменить(новХМЛТело, "</elem>", "</elem>" + СИМВОЛЫ.ПС);
	новХМЛТело = СтрЗаменить(новХМЛТело, "</data>", "</data>" + СИМВОЛЫ.ПС);
	//}
	
	Возврат новХМЛТело;
	
КонецФункции

Функция ПолучитьДокументDOMФормы(XMLСтрокаФормы) Экспорт
	
	ЧтениеXML = Новый ЧтениеXML;
	ЧтениеXML.УстановитьСтроку(XMLСтрокаФормы);
	ПостроительDOM = Новый ПостроительDOM;
	ДокументDOM = ПостроительDOM.Прочитать(ЧтениеXML);
	Возврат ДокументDOM;
	
КонецФункции

//==============================================================================================================================================
// ПРОЦЕДУРЫ ПАРСИНГА МОДУЛЕЙ
//==============================================================================================================================================

Функция ПолучитьТаблицуПроцедурМодуля(ТекстМодуля) Экспорт //с определением достоверного источника затрудняюсь
	
	ТаблицаПроцедурМодуля = Новый ТаблицаЗначений;
	ТаблицаПроцедурМодуля.Колонки.Добавить("ИмяПроцедуры",          Новый ОписаниеТипов("Строка", , Новый КвалификаторыСтроки(100)));
	ТаблицаПроцедурМодуля.Колонки.Добавить("ТекстПроцедуры",        Новый ОписаниеТипов("Строка"));
	ТаблицаПроцедурМодуля.Колонки.Добавить("ВидПроцедуры",          Новый ОписаниеТипов("Число"));
	ТаблицаПроцедурМодуля.Колонки.Добавить("ИндексНачалаПроцедуры", Новый ОписаниеТипов("Число"));
	ТаблицаПроцедурМодуля.Колонки.Добавить("ДлинаПроцедуры",        Новый ОписаниеТипов("Число"));
	
	Если ПустаяСтрока(ТекстМодуля) Тогда
		Возврат ТаблицаПроцедурМодуля;
	КонецЕсли;
	
	ТекущийМодуль = Новый ТекстовыйДокумент();
	ТекущийМодуль.УстановитьТекст(ТекстМодуля);
	
	НомерСтрокиНачалаОператоров = 1;
	НомерСтрокиОкончанияПеременных = ТекущийМодуль.КоличествоСтрок();
	
	ТекстПроцедуры = "";
	СписокОператоров = Новый СписокЗначений;
	СписокОператоров.Добавить("процедура ", "конецпроцедуры");
	СписокОператоров.Добавить("функция ", "конецфункции");
	
	Для Каждого Оператор Из СписокОператоров Цикл
		НайденоНачало = Ложь;
		НайденКонец = Ложь;
		ОператорНачала = Оператор.Значение;
		ОператорКонца = Оператор.Представление;
		ДлинаНачала = СтрДлина(ОператорНачала);
		ДлинаКонца = СтрДлина(ОператорКонца);
		
		ИндексНачалаПроцедуры = 0;
		ДлинаПроцедуры  = 0;
		
		ВидПроцедуры = ?(ОператорНачала = "процедура ", 0, 1);
		
		Для Сч = 1 По ТекущийМодуль.КоличествоСтрок() Цикл
			СтрокаМодуля = ТекущийМодуль.ПолучитьСтроку(Сч);
			
			Если НЕ НайденоНачало Тогда
				ОператорСтроки = Лев(НРег(СокрЛП(СтрокаМодуля)), ДлинаНачала);
				
				НайденоНачало = (ОператорСтроки = ОператорНачала);
				
				Если НайденоНачало Тогда
					ИндексНачалаПроцедуры = ПолучитьНомерСтрокиНачалаКомментарияПроцедуры(Сч, ТекущийМодуль, ТекстПроцедуры);
					
					Поз = Найти(СтрокаМодуля, "(");
					Если Поз = 0 Тогда
						Поз = СтрДлина(СтрокаМодуля);
					Иначе
						Поз = Поз - 1;
					КонецЕсли;
					ИмяПроцедуры = СокрЛП(Сред(СтрокаМодуля, ДлинаНачала + 1, Поз - ДлинаНачала));
					
					Если ИндексНачалаПроцедуры < НомерСтрокиОкончанияПеременных Тогда
						НомерСтрокиОкончанияПеременных = ИндексНачалаПроцедуры - 1;
					КонецЕсли;
					
				Иначе
					Продолжить;
				КонецЕсли;
			КонецЕсли;
			
			Если НайденоНачало Тогда
				ТекстПроцедуры = ?(ТекстПроцедуры = "", "", ТекстПроцедуры + Символы.ПС) + СтрокаМодуля;
			КонецЕсли;
			
			НайденКонец = Лев(НРег(СокрЛП(СтрокаМодуля)), ДлинаКонца) = ОператорКонца;
			//Проверим, что дальше не значащий символ
			Если НайденКонец
				И НЕ ПустаяСтрока(Сред(СокрЛ(СтрокаМодуля), ДлинаКонца + 1, 1))
				И Сред(СтрокаМодуля, ДлинаКонца + 1, 1) <> "/"
				Тогда
				
				НайденКонец = Ложь;
			КонецЕсли;
			
			Если НайденКонец Тогда
				ДлинаПроцедуры = Сч - ИндексНачалаПроцедуры + 1;
				
				Если ТекстПроцедуры <> "" Тогда
					ТекстПроцедурыДляЗаписи = ТекстПроцедуры;
					
					СвойстваПроцедуры = Новый Структура;
					СвойстваПроцедуры.Вставить("ИндексНачалаПроцедуры", ИндексНачалаПроцедуры);
					СвойстваПроцедуры.Вставить("ДлинаПроцедуры", ДлинаПроцедуры);
					СвойстваПроцедуры.Вставить("ТекстПроцедурыДляЗаписи", ТекстПроцедурыДляЗаписи);
					СвойстваПроцедуры.Вставить("ВидПроцедуры", ВидПроцедуры);
					
					ОбработатьПроцедуру(ИмяПроцедуры, ТаблицаПроцедурМодуля, СвойстваПроцедуры);
					
					ТекстПроцедуры = "";
				КонецЕсли;
				
				Если Сч > НомерСтрокиНачалаОператоров Тогда
					НомерСтрокиНачалаОператоров = Сч + 1;
				КонецЕсли;
				НайденоНачало = Ложь;
			КонецЕсли;
		КонецЦикла;
	КонецЦикла;
	
	// Создадим модуль раздела переменных
	Если НомерСтрокиНачалаОператоров <> 1 Тогда
		
		ТекстПеременныхМодуля = Новый ТекстовыйДокумент();
		Для Сч = 1 По НомерСтрокиОкончанияПеременных Цикл
			СтрокаМодуля = ТекущийМодуль.ПолучитьСтроку(Сч);
			ТекстПеременныхМодуля.ДобавитьСтроку(СтрокаМодуля);
		КонецЦикла;
		
		Если ТекстПеременныхМодуля.КоличествоСтрок() <> 0 Тогда
			СвойстваПроцедуры = Новый Структура;
			СвойстваПроцедуры.Вставить("ИндексНачалаПроцедуры", 1);
			СвойстваПроцедуры.Вставить("ДлинаПроцедуры", НомерСтрокиОкончанияПеременных);
			СвойстваПроцедуры.Вставить("ТекстПроцедурыДляЗаписи", ТекстПеременныхМодуля.ПолучитьТекст());
			СвойстваПроцедуры.Вставить("ВидПроцедуры", 2);
			
			ОбработатьПроцедуру("_РазделПеременных_", ТаблицаПроцедурМодуля, СвойстваПроцедуры);
		КонецЕсли;
		
	КонецЕсли;
	
	// Создадим модуль раздела операторов
	ТекстОператоровМодуля = Новый ТекстовыйДокумент();
	Для Сч = НомерСтрокиНачалаОператоров По ТекущийМодуль.КоличествоСтрок() Цикл
		СтрокаМодуля = ТекущийМодуль.ПолучитьСтроку(Сч);
		ТекстОператоровМодуля.ДобавитьСтроку(СтрокаМодуля);
	КонецЦикла;
	
	Если ТекстОператоровМодуля.КоличествоСтрок() <> 0 Тогда
		СвойстваПроцедуры = Новый Структура;
		СвойстваПроцедуры.Вставить("ИндексНачалаПроцедуры", НомерСтрокиНачалаОператоров);
		СвойстваПроцедуры.Вставить("ДлинаПроцедуры", ТекущийМодуль.КоличествоСтрок() - НомерСтрокиНачалаОператоров + 1);
		СвойстваПроцедуры.Вставить("ТекстПроцедурыДляЗаписи", ТекстОператоровМодуля.ПолучитьТекст());
		СвойстваПроцедуры.Вставить("ВидПроцедуры", 3);
		
		ОбработатьПроцедуру("_РазделОператоров_", ТаблицаПроцедурМодуля, СвойстваПроцедуры);
	КонецЕсли;
	
	Возврат ТаблицаПроцедурМодуля;
	
КонецФункции

Функция ПолучитьНомерСтрокиНачалаКомментарияПроцедуры(НомерСтрокиНачалаПроцедуры, ТекущийМодуль, ТекстПроцедуры) //с определением достоверного источника затрудняюсь
	
	Если НомерСтрокиНачалаПроцедуры = 1 Тогда
		Возврат 1;
	КонецЕсли;
	
	НомерСтрокиНачалаКомментарияПроцедуры = НомерСтрокиНачалаПроцедуры;
	СтрокаМодуля = ТекущийМодуль.ПолучитьСтроку(НомерСтрокиНачалаКомментарияПроцедуры - 1);
	СтрокаМодуля = СокрЛ(СтрокаМодуля);
	
	Пока Лев(СтрокаМодуля, 2) = "//"
		ИЛИ Лев(СтрокаМодуля, 1) = "&" Цикл
		
		ТекстПроцедуры = СтрокаМодуля + ?(ТекстПроцедуры = "", "", Символы.ПС + ТекстПроцедуры);
		НомерСтрокиНачалаКомментарияПроцедуры = НомерСтрокиНачалаКомментарияПроцедуры - 1;
		Если НомерСтрокиНачалаКомментарияПроцедуры = 1 Тогда
			Прервать;
		КонецЕсли;
		СтрокаМодуля = ТекущийМодуль.ПолучитьСтроку(НомерСтрокиНачалаКомментарияПроцедуры - 1);
	КонецЦикла;
	
	Возврат НомерСтрокиНачалаКомментарияПроцедуры;
	
КонецФункции

Процедура ОбработатьПроцедуру(ИмяПроцедуры, ТаблицаПроцедурМодуля, СвойстваПроцедуры) //с определением достоверного источника затрудняюсь
	
	ПроцедураОбъект = ТаблицаПроцедурМодуля.Добавить();
	ПроцедураОбъект.ИмяПроцедуры = ИмяПроцедуры;
	ПроцедураОбъект.ИндексНачалаПроцедуры = СвойстваПроцедуры.ИндексНачалаПроцедуры;
	ПроцедураОбъект.ДлинаПроцедуры        = СвойстваПроцедуры.ДлинаПроцедуры;
	ПроцедураОбъект.ТекстПроцедуры        = СвойстваПроцедуры.ТекстПроцедурыДляЗаписи;
	ПроцедураОбъект.ВидПроцедуры          = СвойстваПроцедуры.ВидПроцедуры;
	
КонецПроцедуры

Процедура ПолучитьТаблицуСтруктурногоСравнения(ВремТабПервогоМодуля, ВремТабВторогоМодуля, СтруктурноеСравнениеМодуля, ТолькоИзмененные) Экспорт
	
	Для Каждого ТекущаяСтрока Из ВремТабПервогоМодуля Цикл
		СтрокаСравнения = ВремТабВторогоМодуля.Найти(ТекущаяСтрока.ИмяПроцедуры, "ИмяПроцедуры");
		Если ТолькоИзмененные = Ложь Тогда
			НоваяСтрока = СтруктурноеСравнениеМодуля.Добавить();
			НоваяСтрока.СтруктураПервогоМодуля = ТекущаяСтрока.ИмяПроцедуры;
			НоваяСтрока.ТекстПервогоЭлемента   = ТекущаяСтрока.ТекстПроцедуры;
			НоваяСтрока.ТипПервый			   = ТекущаяСтрока.ВидПроцедуры;
			НоваяСтрока.Сортировка 			   = ТекущаяСтрока.ИмяПроцедуры;
		КонецЕсли;
		Если СтрокаСравнения <> Неопределено  Тогда
			Если ТолькоИзмененные = Истина И СтрЗаменить(СтрЗаменить(СтрЗаменить(СтрокаСравнения.ТекстПроцедуры, " ", ""), Символы.ПС, ""), Символы.Таб, "") <> СтрЗаменить(СтрЗаменить(СтрЗаменить(ТекущаяСтрока.ТекстПроцедуры, " ", ""), Символы.ПС, ""), Символы.Таб, "") Тогда
				НоваяСтрока = СтруктурноеСравнениеМодуля.Добавить();
				НоваяСтрока.СтруктураПервогоМодуля = ТекущаяСтрока.ИмяПроцедуры;
				НоваяСтрока.ТекстПервогоЭлемента   = ТекущаяСтрока.ТекстПроцедуры;
				НоваяСтрока.ТипПервый			   = ТекущаяСтрока.ВидПроцедуры;
				НоваяСтрока.Сортировка 			   = ТекущаяСтрока.ИмяПроцедуры;
				НоваяСтрока.СтруктураВторогоМодуля = СтрокаСравнения.ИмяПроцедуры;
				НоваяСтрока.ТекстВторогоЭлемента   = СтрокаСравнения.ТекстПроцедуры;
				НоваяСтрока.ТипВторой			   = СтрокаСравнения.ВидПроцедуры;
				НоваяСтрока.ЕстьИзменения = 1;
			ИначеЕсли ТолькоИзмененные = Ложь Тогда
				НоваяСтрока.СтруктураВторогоМодуля = СтрокаСравнения.ИмяПроцедуры;
				НоваяСтрока.ТекстВторогоЭлемента   = СтрокаСравнения.ТекстПроцедуры;
				НоваяСтрока.ТипВторой			   = СтрокаСравнения.ВидПроцедуры;
				Если  	СтрЗаменить(СтрЗаменить(СтрЗаменить(СтрокаСравнения.ТекстПроцедуры, " ", ""), Символы.ПС, ""), Символы.Таб, "") <> СтрЗаменить(СтрЗаменить(СтрЗаменить(ТекущаяСтрока.ТекстПроцедуры, " ", ""), Символы.ПС, ""), Символы.Таб, "") Тогда
					НоваяСтрока.ЕстьИзменения = 1;
				КонецЕсли;
			КонецЕсли;
		ИначеЕсли СтрокаСравнения = Неопределено Тогда
			Если ТолькоИзмененные = Истина Тогда
				НоваяСтрока = СтруктурноеСравнениеМодуля.Добавить();
				НоваяСтрока.СтруктураПервогоМодуля = ТекущаяСтрока.ИмяПроцедуры;
				НоваяСтрока.ТекстПервогоЭлемента   = ТекущаяСтрока.ТекстПроцедуры;
				НоваяСтрока.Сортировка 			   = ТекущаяСтрока.ИмяПроцедуры;
				НоваяСтрока.ТипПервый			   = ТекущаяСтрока.ВидПроцедуры;
			КонецЕсли;
			НоваяСтрока.СтруктураВторогоМодуля = "<Отсутствует>";
			НоваяСтрока.ТекстВторогоЭлемента   = "";
			НоваяСтрока.ЕстьИзменения          = 2;
		КонецЕсли;
	КонецЦикла;
	
	Для Каждого Строка Из ВремТабВторогоМодуля Цикл
		Если ВремТабПервогоМодуля.Найти(Строка.ИмяПроцедуры, "ИмяПроцедуры") = Неопределено Тогда
			НоваяСтрока = СтруктурноеСравнениеМодуля.Добавить();
			НоваяСтрока.СтруктураПервогоМодуля = "<Отсутствует>";
			НоваяСтрока.СтруктураВторогоМодуля = Строка.ИмяПроцедуры;
			НоваяСтрока.ТекстВторогоЭлемента   = Строка.ТекстПроцедуры;
			НоваяСтрока.ТипПервый              = Строка.ВидПроцедуры;
			НоваяСтрока.ТипВторой              = Строка.ВидПроцедуры;
			НоваяСтрока.Сортировка             = Строка.ИмяПроцедуры;
			НоваяСтрока.ЕстьИзменения          = 3;
		КонецЕсли;
	КонецЦикла;
	
	СтруктурноеСравнениеМодуля.Сортировать("ЕстьИзменения Убыв, Сортировка Возр");
	
	////помещаем строку _РазделПеременных_ в самое начало
	//СтрокаПеременных = СтруктурноеСравнениеМодуля.Найти("_РазделПеременных_", "Сортировка");
	//Если СтрокаПеременных <> Неопределено Тогда
	//	Если СтрокаПеременных.ЕстьИзменения <> 0 Тогда
	//		СтруктурноеСравнениеМодуля.Сдвинуть(СтрокаПеременных, -СтруктурноеСравнениеМодуля.Индекс(СтрокаПеременных));
	//	ИначеЕсли ТолькоИзмененные = Ложь Тогда
	//		СтруктурноеСравнениеМодуля.Удалить(СтрокаПеременных);
	//	КонецЕсли;
	//КонецЕсли;
	////помещаем строку _РазделОператоров_ в самый конец
	//СтрокаОператоров = СтруктурноеСравнениеМодуля.Найти("_РазделОператоров_", "Сортировка");
	//Если СтрокаОператоров <> Неопределено Тогда
	//	Если СтрокаОператоров.ЕстьИзменения <> 0 Тогда
	//		Смещение = СтруктурноеСравнениеМодуля.Количество() - СтруктурноеСравнениеМодуля.Индекс(СтрокаОператоров) - 1;
	//		СтруктурноеСравнениеМодуля.Сдвинуть(СтрокаОператоров, Смещение);
	//	ИначеЕсли ТолькоИзмененные = Ложь Тогда
	//		СтруктурноеСравнениеМодуля.Удалить(СтрокаОператоров);
	//	КонецЕсли;
	//КонецЕсли;
	
КонецПроцедуры

//==============================================================================================================================================
// ПРОЦЕДУРЫ И ФУНКЦИИ ОБЩЕГО НАЗНАЧЕНИЯ
//==============================================================================================================================================

Процедура ОткрытьВПроводнике(Файл) Экспорт
	
	SA = Новый COMОбъект("Shell.Application");
	Cч = SA.Windows().Count;
	SA.Explore(Файл.Путь);
	Пока SA.Windows().Count = Cч Цикл
	КонецЦикла;
	Инд = 1;
	Для Каждого  Window Из SA.Windows() Цикл
		Если  Инд = SA.Windows().Count И Window.LocationURL = "file:///" + СтрЗаменить(СтрЗаменить(Лев(Файл.Путь, СтрДлина(Файл.Путь) - 1), "\", "/"), " ", "%20") Тогда
			Window.Document.SelectItem(Файл.ПолноеИмя, 16 + 8 + 1);
		КонецЕсли;
		Инд = Инд + 1;
	КонецЦикла;
	Возврат;
	
КонецПроцедуры

Функция ПолучитьСтандартныйРеквизитИзВнутреннегоПредставления(ВидМетаданных) Экспорт
	
	Если ВидМетаданных = "Справочник" Тогда
		СтруктураСтандартныхРеквизитов = Новый Структура("v2, v3, v4, v5, v6, v7, v8, v10, v13", "СтандартныйРеквизит.Код", "СтандартныйРеквизит.Наименование", "СтандартныйРеквизит.Родитель", "СтандартныйРеквизит.Владелец", "СтандартныйРеквизит.ЭтоГруппа", "СтандартныйРеквизит.ПометкаУдаления", "СтандартныйРеквизит.Ссылка", "СтандартныйРеквизит.Предопределенный", "СтандартныйРеквизит.ИмяПредопределенныхДанных");
	ИначеЕсли ВидМетаданных = "Документ" Тогда
		СтруктураСтандартныхРеквизитов = Новый Структура("v2, v3, v4, v5, v7, v8", "СтандартныйРеквизит.Номер", "СтандартныйРеквизит.Дата", "СтандартныйРеквизит.ПометкаУдаления", "СтандартныйРеквизит.Ссылка", "СтандартныйРеквизит.Проведен", "СтандартныйРеквизит.Движения");
	ИначеЕсли ВидМетаданных = "ЖурналДокументов" Тогда
		СтруктураСтандартныхРеквизитов = Новый Структура("v2, v4, v7, v100, v101, v60003", "СтандартныйРеквизит.Номер", "СтандартныйРеквизит.ПометкаУдаления", "СтандартныйРеквизит.Проведен", "СтандартныйРеквизит.Дата", "СтандартныйРеквизит.Ссылка", "СтандартныйРеквизит.Тип");
	ИначеЕсли ВидМетаданных = "ПланВидовХарактеристик" Тогда
		СтруктураСтандартныхРеквизитов = Новый Структура("v2, v4, v5, v6, v7, v8, v9, v11, v14", "СтандартныйРеквизит.Ссылка", "СтандартныйРеквизит.ПометкаУдаления", "СтандартныйРеквизит.Предопределенный", "СтандартныйРеквизит.Родитель", "СтандартныйРеквизит.ЭтоГруппа", "СтандартныйРеквизит.Код", "СтандартныйРеквизит.Наименование", "СтандартныйРеквизит.ТипЗначения", "СтандартныйРеквизит.ИмяПредопределенныхДанных");
	ИначеЕсли ВидМетаданных = "ПланСчетов" Тогда
		СтруктураСтандартныхРеквизитов = Новый Структура("v2, v4, v5, v6, v7, v8, v10, v11, v12, v17, v28", "СтандартныйРеквизит.Ссылка", "СтандартныйРеквизит.ПометкаУдаления", "СтандартныйРеквизит.Предопределенный", "СтандартныйРеквизит.Родитель", "СтандартныйРеквизит.Код", "СтандартныйРеквизит.Наименование", "СтандартныйРеквизит.Вид", "СтандартныйРеквизит.Забалансовый", "РеквизитСтандартнойТабличнойЧасти.ВидыСубконто", "СтандартныйРеквизит.Порядок", "СтандартныйРеквизит.ИмяПредопределенныхДанных");
	ИначеЕсли ВидМетаданных = "ПланВидовРасчета" Тогда
		СтруктураСтандартныхРеквизитов = Новый Структура("v2, v3, v4, v5, v6, v8, v10, v11, v20, v30", "СтандартныйРеквизит.Код", "СтандартныйРеквизит.Наименование", "СтандартныйРеквизит.ПериодДействияБазовый", "СтандартныйРеквизит.ПометкаУдаления", "СтандартныйРеквизит.Ссылка", "СтандартныйРеквизит.Предопределенный", "РеквизитСтандартнойТабличнойЧасти.БазовыеВидыРасчета", "СтандартныйРеквизит.ИмяПредопределенныхДанных", "РеквизитСтандартнойТабличнойЧасти.ВытесняющиеВидыРасчета", "РеквизитСтандартнойТабличнойЧасти.ВедущиеВидыРасчета");
	ИначеЕсли ВидМетаданных = "РегистрСведений" Тогда
		СтруктураСтандартныхРеквизитов = Новый Структура("v2, v3, v4, v5", "СтандартныйРеквизит.Период", "СтандартныйРеквизит.Регистратор", "СтандартныйРеквизит.НомерСтроки", "СтандартныйРеквизит.Активность");
	ИначеЕсли ВидМетаданных = "РегистрНакопления" Тогда
		СтруктураСтандартныхРеквизитов = Новый Структура("v2, v3, v4, v5, v9", "СтандартныйРеквизит.Период", "СтандартныйРеквизит.Регистратор", "СтандартныйРеквизит.НомерСтроки", "СтандартныйРеквизит.Активность", "СтандартныйРеквизит.ВидДвижения");
	ИначеЕсли ВидМетаданных = "РегистрБухгалтерии" Тогда
		СтруктураСтандартныхРеквизитов = Новый Структура("v2, v3, v4, v5, v9, v10", "СтандартныйРеквизит.Период", "СтандартныйРеквизит.Регистратор", "СтандартныйРеквизит.НомерСтроки", "СтандартныйРеквизит.Активность", "СтандартныйРеквизит.ВидДвижения", "СтандартныйРеквизит.Счет");
	ИначеЕсли ВидМетаданных = "РегистрРасчета" Тогда
		СтруктураСтандартныхРеквизитов = Новый Структура("v2, v3, v4, v5, v6, v7, v8, v9, v10, v11, v13", "СтандартныйРеквизит.Регистратор", "СтандартныйРеквизит.НомерСтроки", "СтандартныйРеквизит.ВидРасчета", "СтандартныйРеквизит.ПериодДействия", "СтандартныйРеквизит.ПериодДействияНачало", "СтандартныйРеквизит.ПериодДействияКонец", "СтандартныйРеквизит.БазовыйПериодНачало", "СтандартныйРеквизит.БазовыйПериодКонец", "СтандартныйРеквизит.Активность", "СтандартныйРеквизит.Сторно", "СтандартныйРеквизит.ПериодРегистрации");
	ИначеЕсли ВидМетаданных = "БизнесПроцесс" Тогда
		СтруктураСтандартныхРеквизитов = Новый Структура("v2, v3, v4, v5, v7, v8, v9", "СтандартныйРеквизит.Номер", "СтандартныйРеквизит.Дата", "СтандартныйРеквизит.ПометкаУдаления", "СтандартныйРеквизит.Ссылка", "СтандартныйРеквизит.Завершен", "СтандартныйРеквизит.ВедущаяЗадача", "СтандартныйРеквизит.Стартован");
	ИначеЕсли ВидМетаданных = "Задача" Тогда
		СтруктураСтандартныхРеквизитов = Новый Структура("v2, v3, v4, v5, v7, v8, v9, v10", "СтандартныйРеквизит.Номер", "СтандартныйРеквизит.Дата", "СтандартныйРеквизит.ПометкаУдаления", "СтандартныйРеквизит.Ссылка", "СтандартныйРеквизит.БизнесПроцесс", "СтандартныйРеквизит.ТочкаМаршрута", "СтандартныйРеквизит.Наименование", "СтандартныйРеквизит.Выполнена");
	ИначеЕсли ВидМетаданных = "ПланОбмена" Тогда
		СтруктураСтандартныхРеквизитов = Новый Структура("v2, v3, v4, v6, v9, v10, v13", "СтандартныйРеквизит.Код", "СтандартныйРеквизит.Наименование", "СтандартныйРеквизит.ПометкаУдаления", "СтандартныйРеквизит.Ссылка", "СтандартныйРеквизит.НомерОтправленного", "СтандартныйРеквизит.НомерПринятого", "СтандартныйРеквизит.ЭтотУзел");
	ИначеЕсли ВидМетаданных = "ТабличнаяЧасть" Тогда
		СтруктураСтандартныхРеквизитов = Новый Структура("v3, v10", "СтандартныйРеквизит.НомерСтроки", "СтандартныйРеквизит.НомерСтроки");
	ИначеЕсли ВидМетаданных = "Перечисление" Тогда
		СтруктураСтандартныхРеквизитов = Новый Структура("v2, v3", "СтандартныйРеквизит.Ссылка", "СтандартныйРеквизит.Порядок");
	КонецЕсли;
	
	Возврат СтруктураСтандартныхРеквизитов;
	
КонецФункции

Функция ТекстовоеСравнениеВоВременныхФайлах(ПервыйТекст, ВторойТекст, ПервыйПрефикс = Неопределено, ВторойПрефикс = Неопределено) Экспорт
	
	#Если ТолстыйКлиентОбычноеПриложение Тогда
		ПервыйВременныйФайлРаспаковки = ПолучитьИмяВременногоФайла("txt");
		ВторойВременныйФайлРаспаковки = ПолучитьИмяВременногоФайла("txt");
		Если ПервыйПрефикс <> Неопределено И Найти(ПервыйПрефикс, "<Отсутствует>") = 0 Тогда
			ПервыйВременныйФайлРаспаковки = Лев(ПервыйВременныйФайлРаспаковки, Найти(ПервыйВременныйФайлРаспаковки, "v8_") + 7) + ПервыйПрефикс + "_" + Прав(ПервыйВременныйФайлРаспаковки, СтрДлина(ПервыйВременныйФайлРаспаковки) - Найти(ПервыйВременныйФайлРаспаковки, "v8_") - 7);
		КонецЕсли;
		Если ВторойПрефикс <> Неопределено И Найти(ВторойПрефикс, "<Отсутствует>") = 0 Тогда
			ВторойВременныйФайлРаспаковки = Лев(ВторойВременныйФайлРаспаковки, Найти(ВторойВременныйФайлРаспаковки, "v8_") + 7) + ВторойПрефикс + "_" + Прав(ВторойВременныйФайлРаспаковки, СтрДлина(ВторойВременныйФайлРаспаковки) - Найти(ВторойВременныйФайлРаспаковки, "v8_") - 7);
		КонецЕсли;
		ТекстПервогоФайла = Новый ТекстовыйДокумент;
		ТекстПервогоФайла.УстановитьТекст(ПервыйТекст);
		ТекстПервогоФайла.Записать(ПервыйВременныйФайлРаспаковки);
		ТекстВторогоФайла = Новый ТекстовыйДокумент;
		ТекстВторогоФайла.УстановитьТекст(ВторойТекст);
		ТекстВторогоФайла.Записать(ВторойВременныйФайлРаспаковки);
		СравнениеВременныхФайлов = Новый СравнениеФайлов;
		СравнениеВременныхФайлов.ПервыйФайл = ПервыйВременныйФайлРаспаковки;
		СравнениеВременныхФайлов.ВторойФайл = ВторойВременныйФайлРаспаковки;
		СравнениеВременныхФайлов.СпособСравнения = СпособСравненияФайлов.ТекстовыйДокумент;
		СравнениеВременныхФайлов.УчитыватьРегистр = Истина;
		СравнениеВременныхФайлов.ИгнорироватьПустоеПространство = Истина;
	#Иначе
		СравнениеВременныхФайлов = Неопределено;
	#КонецЕсли
	
	Возврат СравнениеВременныхФайлов;
	
КонецФункции

Процедура ОткрытьСравнение(ПутьФайла1, ПутьФайла2) Экспорт
	
	СоответствиеВидовФайлов = ПостроитьСоответствиеВидовФайлов();
	
	Файл1 = Новый Файл(ПутьФайла1);
	Файл2 = Новый Файл(ПутьФайла2);
	
	Если Файл2.Существует() Тогда
		Расширение = НРег(Сред(Файл2.Расширение, 2))
	ИначеЕсли Файл1.Существует() Тогда
		Расширение = НРег(Сред(Файл1.Расширение, 2));
	Иначе
		Расширение = "";
	КонецЕсли;
	
	Если СоответствиеВидовФайлов.Получить(Расширение) <> Неопределено Тогда
		
		Если СоответствиеВидовФайлов.Получить(Расширение) < 9 Тогда
			
			Форм = ПолучитьФорму("Форма", , "КлючУникальности");
			Форм.Открыть();
			
			ФайлКонфигурации = ПутьФайла1;
			ФайлОбновления = ПутьФайла2;
			КаталогДляРаспаковкиОбновления = "";
			КаталогДляРаспаковкиКонфигурации = "";
			РежимСравнения = 1;
			
			РежимВыбораОбъекта = СоответствиеВидовФайлов.Получить(Расширение);
			
			Форм.ПростоеСравнение();
			
		ИначеЕсли СоответствиеВидовФайлов.Получить(Расширение) = 102 Тогда
			
			СравнитьСериализованныеMXL(ПутьФайла1, ПутьФайла2);
			
		Иначе
			
			СравнениеПроизвольныхФайлов(ПутьФайла1, ПутьФайла2);
			
		КонецЕсли;
		
	Иначе
		
		СравнениеПроизвольныхФайлов(ПутьФайла1, ПутьФайла2);
		
	КонецЕсли;
	
КонецПроцедуры

Процедура СравнениеПроизвольныхФайлов(Путь1, Путь2) Экспорт
	
	#Если ТолстыйКлиентОбычноеПриложение Тогда
		Сравнение = Новый СравнениеФайлов;
		Сравнение.ПервыйФайл = ФайлКонфигурации;
		Сравнение.ВторойФайл = ФайлОбновления;
		Сравнение.ИгнорироватьПустоеПространство = Истина;
		Сравнение.УчитыватьРегистр = Истина;
		
		Попытка
			Сравнение.СпособСравнения = СпособСравненияФайлов.ТекстовыйДокумент;
			Сравнение.ПоказатьРазличияМодально();
		Исключение
			Попытка
				Сравнение.СпособСравнения = СпособСравненияФайлов.ТабличныйДокумент;
				Сравнение.ПоказатьРазличияМодально();
			Исключение
				Сравнение.СпособСравнения = СпособСравненияФайлов.Двоичное;
				Сравнение.ПоказатьРазличияМодально();
			КонецПопытки;
		КонецПопытки;
		Возврат;
	#КонецЕсли
	
	
КонецПроцедуры

Процедура СравнитьСериализованныеMXL(Путь1, Путь2) Экспорт
	
	#Если ТолстыйКлиентОбычноеПриложение Тогда
		Попытка
			ПервыйВременныйФайлРаспаковки = ПолучитьИмяВременногоФайла("mxl");
			ВторойВременныйФайлРаспаковки = ПолучитьИмяВременногоФайла("mxl");
			
			ЧтениеХМЛ1 =  Новый ЧтениеXML;
			ЧтениеХМЛ1.ОткрытьФайл(Путь1);
			ТабДок1 = СериализаторXDTO.ПрочитатьXML(ЧтениеХМЛ1, Тип("ТабличныйДокумент"));
			ТабДок1.Записать(ПервыйВременныйФайлРаспаковки);
			
			ЧтениеХМЛ2 =  Новый ЧтениеXML;
			ЧтениеХМЛ2.ОткрытьФайл(Путь2);
			ТабДок2 = СериализаторXDTO.ПрочитатьXML(ЧтениеХМЛ2, Тип("ТабличныйДокумент"));
			ТабДок2.Записать(ВторойВременныйФайлРаспаковки);
			
			СравнениеВременныхФайлов = Новый СравнениеФайлов;
			СравнениеВременныхФайлов.ПервыйФайл = ПервыйВременныйФайлРаспаковки;
			СравнениеВременныхФайлов.ВторойФайл = ВторойВременныйФайлРаспаковки;
			СравнениеВременныхФайлов.СпособСравнения = СпособСравненияФайлов.ТабличныйДокумент;
			СравнениеВременныхФайлов.УчитыватьРегистр = Истина;
			СравнениеВременныхФайлов.ИгнорироватьПустоеПространство = Истина;
			СравнениеВременныхФайлов.ПоказатьРазличияМодально();
			
		Исключение
			Предупреждение("Неподдерживаемый формат xml-файла");
		КонецПопытки;
	#КонецЕсли
	
КонецПроцедуры

Функция ПостроитьСоответствиеВидовФайлов() Экспорт
	
	СоответствиеВидовФайлов = Новый Соответствие;
	СоответствиеВидовФайлов.Вставить("cf", 0);
	СоответствиеВидовФайлов.Вставить("cfu", 2);
	СоответствиеВидовФайлов.Вставить("epf", 1);
	СоответствиеВидовФайлов.Вставить("erf", 3);
	СоответствиеВидовФайлов.Вставить("ssf", 4);
	СоответствиеВидовФайлов.Вставить("form", 4);
	СоответствиеВидовФайлов.Вставить("mxl", 100);
	СоответствиеВидовФайлов.Вставить("txt", 101);
	СоответствиеВидовФайлов.Вставить("xml", 102);
	
	Возврат СоответствиеВидовФайлов;

КонецФункции

Функция Версия() Экспорт
	
	Версия = "1.13";
	Возврат Версия;
	
КонецФункции

//==============================================================================================================================================
// ОПЕРАТОРЫ ОСНОВНОЙ ПРОГРАММЫ
//==============================================================================================================================================



