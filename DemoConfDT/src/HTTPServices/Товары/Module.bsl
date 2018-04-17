
Функция ПутьКТоваруGET(Запрос)
	
	Перем Ответ, Выборка, СтрокаXML;
	
	Попытка
		
		Если Запрос.ПараметрыURL["*"] = "" Тогда
			Выборка = ПолучитьТоварыПоКодуИРодителю(, Справочники.Товары.ПустаяСсылка());	
			СтрокаXML = СоздатьXMLПоВыборке(Выборка);
		Иначе
			
			Параметры = РазложитьСтрокуВМассивПодстрок(Запрос.ПараметрыURL["*"], "/");	
			Родитель = Неопределено;
			Для НомерЧастьПути = 0 По Параметры.Количество()-1 Цикл			
				Выборка
				   = ПолучитьТоварыПоКодуИРодителю(Параметры[НомерЧастьПути], Родитель);
				
				Если Выборка.Следующий() Тогда 
					//Дошли до последнего сегмента в пути.
					// Отдельный товар выводим, группу раскрываем и выводим
					Если НомерЧастьПути = Параметры.Количество()-1 Тогда
						Если Выборка.ЭтоГруппа Тогда
							Выборка = ПолучитьТоварыПоКодуИРодителю(,Выборка.ПолучитьОбъект().Ссылка);	
							СтрокаXML = СоздатьXMLПоВыборке(Выборка);
						Иначе
							СтрокаXML = СоздатьXMLПоЭлементу(Выборка.ПолучитьОбъект());
						КонецЕсли
					Иначе
						// Продолжаем движение по сегментам пути. 
						//Для группы получаем дочерние товары и группы
						Если Выборка.ЭтоГруппа Тогда
							Родитель = Выборка.Ссылка;
						Иначе
							Ответ = Новый HTTPСервисОтвет(400);
							Ответ.УстановитьТелоИзСтроки(
						    	"Элемент " + Параметры[НомерЧастьПути] + " не является группой"  );
							Возврат Ответ;
						КонецЕсли
					КонецЕсли
				Иначе
					// Элемент (товар или группа) не найден
					Ответ = Новый HTTPСервисОтвет(404);
					Возврат Ответ;
				КонецЕсли; 
			
			КонецЦикла; 
		КонецЕсли;	
		
		Ответ = Новый HTTPСервисОтвет(200);
		Ответ.УстановитьТелоИзСтроки(СтрокаXML);
		// Помогает клиенту понять, что же за данные к нему пришли
		// Браузеры, например, применят удобный подсветку XML-синтаксиса
		Ответ.Заголовки.Вставить("Content-type", "application/xml");	
		
	Исключение
		// В диагностике ошибки хотим оставить только сообщение,
		// без строки и модуля.
		// Это не обязательно лучшая практика, во многих случаях
		// вполне можно вернуть потребителю эту информацию.
		Ответ = Новый HTTPСервисОтвет(500);
		Информация = ИнформацияОбОшибке();
		Сообщение = Информация.Описание;
		Если Информация.Причина <> Неопределено Тогда
			Сообщение = Сообщение + ":" + Информация.Причина.Описание;
		КонецЕсли;
		Ответ.УстановитьТелоИзСтроки(Сообщение);
	КонецПопытки;
	
	Возврат Ответ;
	
	
	
КонецФункции

Функция СоздатьXMLПоВыборке(Выборка)
    
    Перем ЕстьЕщеЭлементы, ЗаписьXML, Строка;
    
	ЗаписьXML =  Новый ЗаписьXML();
	ЗаписьXML.УстановитьСтроку();
	ЗаписьXML.ЗаписатьОбъявлениеXML();
	ЗаписьXML.ЗаписатьНачалоЭлемента("Products");
	
	ЕстьЕщеЭлементы = Выборка.Следующий();
	Пока ЕстьЕщеЭлементы Цикл	
		ЗаписатьXML(ЗаписьXML, Выборка.ПолучитьОбъект());		
		ЕстьЕщеЭлементы = Выборка.Следующий();
	КонецЦикла; 
	
	ЗаписьXML.ЗаписатьКонецЭлемента();
	Строка = ЗаписьXML.Закрыть();

	Возврат Строка;

КонецФункции

Функция СоздатьXMLПоЭлементу(Элемент)
	
	ЗаписьXML =  Новый ЗаписьXML();
	ЗаписьXML.УстановитьСтроку();
	ЗаписьXML.ЗаписатьОбъявлениеXML();
	ЗаписьXML.ЗаписатьНачалоЭлемента("Products");
    ЗаписатьXML(ЗаписьXML, Элемент);
	ЗаписьXML.ЗаписатьКонецЭлемента();
	Строка = ЗаписьXML.Закрыть();		
	Возврат Строка;

КонецФункции


Функция ПолучитьТоварыПоКодуИРодителю(Код = "", Родитель = Неопределено)

   
	   Отбор = Новый Структура();
	   Если Код <> "" Тогда
		  Отбор.Вставить("Код", Код); 
	   КонецЕсли; 
	   
	   Если Родитель <> Неопределено Тогда
		   Выборка = Справочники.Товары.Выбрать(Родитель,, Отбор);	   
	   Иначе	   
		   Выборка = Справочники.Товары.Выбрать(,, Отбор);	   
	   КонецЕсли; 
       
	   
	   Возврат Выборка;   

КонецФункции // ПолучитьТоварыПоИмениИРодителю()

Функция РазложитьСтрокуВМассивПодстрок(Знач Стр,Разделитель = ",", УдалятьПустыеСтроки = Истина) Экспорт 
	
	Массив = Новый Массив();
	ИзмененнаяСтрока = СтрЗаменить(Стр, Разделитель, Символы.ПС);
	
	Для Счетчик = 1 По СтрЧислоВхождений(ИзмененнаяСтрока, Символы.ПС)+1 Цикл
		Строка = СтрПолучитьСтроку(ИзмененнаяСтрока, Счетчик);
		Если Строка <> "" Тогда		
			 Массив.Добавить(Строка);		
		КонецЕсли; 	 
    КонецЦикла; 
  
  Возврат Массив;
	
КонецФункции

Функция ПутьКТоваруDELETE(Запрос)
	
	Перем Ответ, Выборка;
	
	Попытка
		
		Если Запрос.ПараметрыURL["*"] = "" Тогда
			// Все товары удалять запретим
			Ответ = Новый HTTPСервисОтвет(400);
			Ответ.УстановитьТелоИзСтроки("Нельзя удалить все товары!");
			Возврат Ответ;
		Иначе
			
			Параметры = РазложитьСтрокуВМассивПодстрок(Запрос.ПараметрыURL["*"], "/");	
			Родитель = Неопределено;
			Для НомерЧастьПути = 0 По Параметры.Количество()-1 Цикл			
				Выборка
				   = ПолучитьТоварыПоКодуИРодителю(Параметры[НомерЧастьПути], Родитель);
				
				Если Выборка.Следующий() Тогда 
					//Дошли до последнего сегмента в пути.
					// Отдельный товар выводим, группу раскрываем и выводим
					Если НомерЧастьПути = Параметры.Количество()-1 Тогда
						Выборка.ПолучитьОбъект().УстановитьПометкуУдаления(Истина);
						Если Выборка.ЭтоГруппа Тогда
							ВыборкаДочерних = ПолучитьТоварыПоКодуИРодителю(,Выборка.ПолучитьОбъект().Ссылка);
							ЕстьЕщеЭлементы = ВыборкаДочерних.Следующий();
							Пока ЕстьЕщеЭлементы Цикл	
								ВыборкаДочерних.ПолучитьОбъект().УстановитьПометкуУдаления(Истина);
								ЕстьЕщеЭлементы = Выборка.Следующий();
							КонецЦикла; 							
						КонецЕсли
					Иначе
						// Продолжаем движение по сегментам пути. 
						//Для группы получаем дочерние товары и группы
						Если Выборка.ЭтоГруппа Тогда
							Родитель = Выборка.Ссылка;
						Иначе
							Ответ = Новый HTTPСервисОтвет(400);
							Ответ.УстановитьТелоИзСтроки(
						    	"Элемент " + Параметры[НомерЧастьПути] + " не является группой"  );
							Возврат Ответ;
						КонецЕсли
					КонецЕсли
				Иначе
					// Элемент (товар или группа) не найден
					Ответ = Новый HTTPСервисОтвет(404);
					Возврат Ответ;
				КонецЕсли; 
			
			КонецЦикла; 
		КонецЕсли;	
		
		// Код ответа 204 - No Content
		Ответ = Новый HTTPСервисОтвет(204);

		
	Исключение
		Ответ = Новый HTTPСервисОтвет(500);
		Информация = ИнформацияОбОшибке();
		Сообщение = Информация.Описание;
		Если Информация.Причина <> Неопределено Тогда
			Сообщение = Сообщение + ":" + Информация.Причина.Описание;
		КонецЕсли;
		Ответ.УстановитьТелоИзСтроки(Сообщение);
	КонецПопытки;
	
	Возврат Ответ;

КонецФункции
