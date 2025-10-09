`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09.10.2025 13:43:34
// Design Name: 
// Module Name: tb_bram
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tb_bram;


  // Параметры тестбенча
  parameter RAM_WIDTH     = 32;
  parameter RAM_ADDR_BITS = 4;  // Уменьшено для простоты тестирования
  parameter RAM_DEPTH     = 2**RAM_ADDR_BITS;
  parameter CLK_PERIOD    = 10;

  // Сигналы тестбенча
  logic                     clk_i;
  logic [RAM_ADDR_BITS-1:0] addr_a_i;
  logic [RAM_ADDR_BITS-1:0] addr_b_i;
  logic [RAM_WIDTH-1:0]     data_a_i;
  logic [RAM_WIDTH-1:0]     data_b_i;
  logic                     we_a_i;
  logic                     we_b_i;
  logic                     en_a_i;
  logic                     en_b_i;
  logic [RAM_WIDTH-1:0]     data_a_o;
  logic [RAM_WIDTH-1:0]     data_b_o;

  // Счетчик тактов
  int cycle_count;

  // Экземпляр тестируемого модуля
  true_dual_port #(
    .RAM_WIDTH(RAM_WIDTH),
    .RAM_ADDR_BITS(RAM_ADDR_BITS)
  ) dut (
    .clk_i(clk_i),
    .addr_a_i(addr_a_i),
    .addr_b_i(addr_b_i),
    .data_a_i(data_a_i),
    .data_b_i(data_b_i),
    .we_a_i(we_a_i),
    .we_b_i(we_b_i),
    .en_a_i(en_a_i),
    .en_b_i(en_b_i),
    .data_a_o(data_a_o),
    .data_b_o(data_b_o)
  );

  // Генератор тактового сигнала
  initial begin
    clk_i = 0;
    forever #(CLK_PERIOD/2) clk_i = ~clk_i;
  end

  // Основной процесс тестирования
  initial begin
    // Инициализация сигналов
    initialize();
    
    $display("=== Начало тестирования BRAM ===");
    $display("Время: %0t", $time);
    
    // Тест 1: Запись через порт A, чтение через порт A
    $display("\n--- Тест 1: Запись и чтение через порт A ---");
    test_write_read_port_a();
    
    // Тест 2: Запись через порт B, чтение через порт B
    $display("\n--- Тест 2: Запись и чтение через порт B ---");
    test_write_read_port_b();
    
    // Тест 3: Одновременная работа обоих портов
    $display("\n--- Тест 3: Одновременная работа портов A и B ---");
    test_simultaneous_ports();
    
    // Тест 4: Конфликт записи в одну ячейку
    $display("\n--- Тест 4: Конфликт записи в одну ячейку ---");
    test_write_conflict();
    
    // Тест 5: Тестирование отключенных портов
    $display("\n--- Тест 5: Тестирование отключенных портов ---");
    test_disabled_ports();
    
    $display("\n=== Тестирование завершено ===");
    $display("Всего тактов: %0d", cycle_count);
    $finish;
  end

  // Счетчик тактов
  always @(posedge clk_i) begin
    cycle_count <= cycle_count + 1;
  end

  // Задача инициализации
  task initialize();
    addr_a_i = '0;
    addr_b_i = '0;
    data_a_i = '0;
    data_b_i = '0;
    we_a_i   = '0;
    we_b_i   = '0;
    en_a_i   = '0;
    en_b_i   = '0;
    cycle_count = 0;
    wait_n_cycles(2);
  endtask

  // Задача ожидания N тактов
  task wait_n_cycles(int n);
    repeat(n) @(posedge clk_i);
  endtask

  // Тест: запись и чтение через порт A
  task test_write_read_port_a();
    // Запись данных через порт A
    for (int i = 0; i < 4; i++) begin
      @(posedge clk_i);
      en_a_i   <= 1;
      we_a_i   <= 1;
      addr_a_i <= i;
      data_a_i <= i + 8'h10;
      $display("Запись через порт A: addr=%0d, data=0x%h", i, i + 8'h10);
    end
    
    // Отключение записи
    @(posedge clk_i);
    we_a_i <= 0;
    wait_n_cycles(1);
    
    // Чтение данных через порт A
    for (int i = 0; i < 4; i++) begin
      @(posedge clk_i);
      en_a_i   <= 1;
      we_a_i   <= 0;
      addr_a_i <= i;
      wait_n_cycles(1);
      $display("Чтение через порт A: addr=%0d, data=0x%h (ожидается 0x%h)", 
               i, data_a_o, i + 8'h10);
      assert(data_a_o == i + 8'h10) else $error("Ошибка чтения порта A!");
    end
    
    @(posedge clk_i);
    en_a_i <= 0;
  endtask

  // Тест: запись и чтение через порт B
  task test_write_read_port_b();
    // Запись данных через порт B
    for (int i = 4; i < 8; i++) begin
      @(posedge clk_i);
      en_b_i   <= 1;
      we_b_i   <= 1;
      addr_b_i <= i;
      data_b_i <= i + 8'h20;
      $display("Запись через порт B: addr=%0d, data=0x%h", i, i + 8'h20);
    end
    
    // Отключение записи
    @(posedge clk_i);
    we_b_i <= 0;
    wait_n_cycles(1);
    
    // Чтение данных через порт B
    for (int i = 4; i < 8; i++) begin
      @(posedge clk_i);
      en_b_i   <= 1;
      we_b_i   <= 0;
      addr_b_i <= i;
      wait_n_cycles(1);
      $display("Чтение через порт B: addr=%0d, data=0x%h (ожидается 0x%h)", 
               i, data_b_o, i + 8'h20);
      assert(data_b_o == i + 8'h20) else $error("Ошибка чтения порта B!");
    end
    
    @(posedge clk_i);
    en_b_i <= 0;
  endtask

  // Тест: одновременная работа портов
  task test_simultaneous_ports();
    // Одновременная запись в разные адреса
    @(posedge clk_i);
    en_a_i   <= 1;
    en_b_i   <= 1;
    we_a_i   <= 1;
    we_b_i   <= 1;
    addr_a_i <= 10;
    addr_b_i <= 11;
    data_a_i <= 8'hAA;
    data_b_i <= 8'hBB;
    $display("Одновременная запись: A(addr=10)=0xAA, B(addr=11)=0xBB");
    
    @(posedge clk_i);
    we_a_i <= 0;
    we_b_i <= 0;
    wait_n_cycles(1);
    
    // Одновременное чтение из разных адресов
    @(posedge clk_i);
    addr_a_i <= 10;
    addr_b_i <= 11;
    wait_n_cycles(1);
    $display("Одновременное чтение: A(addr=10)=0x%h, B(addr=11)=0x%h", 
             data_a_o, data_b_o);
    assert(data_a_o == 8'hAA) else $error("Ошибка чтения порта A!");
    assert(data_b_o == 8'hBB) else $error("Ошибка чтения порта B!");
    
    @(posedge clk_i);
    en_a_i <= 0;
    en_b_i <= 0;
  endtask

  // Тест: конфликт записи
  task test_write_conflict();
    // Попытка записи в один адрес с обоих портов
    @(posedge clk_i);
    en_a_i   <= 1;
    en_b_i   <= 1;
    we_a_i   <= 1;
    we_b_i   <= 1;
    addr_a_i <= 12;
    addr_b_i <= 12;  // Тот же адрес!
    data_a_i <= 8'hCC;
    data_b_i <= 8'hDD;
    $display("Конфликт записи: оба порта пишут в addr=12");
    $display("Порт A: data=0xCC, Порт B: data=0xDD");
    
    @(posedge clk_i);
    we_a_i <= 0;
    we_b_i <= 0;
    wait_n_cycles(1);
    
    // Проверка, какое значение записалось
    @(posedge clk_i);
    addr_a_i <= 12;
    wait_n_cycles(1);
    $display("Результат конфликта: data=0x%h", data_a_o);
    // В реальной BRAM поведение при конфликте может зависеть от реализации
    
    @(posedge clk_i);
    en_a_i <= 0;
    en_b_i <= 0;
  endtask

  // Тест: отключенные порты
  task test_disabled_ports();
    // Запись данных
    @(posedge clk_i);
    en_a_i   <= 1;
    we_a_i   <= 1;
    addr_a_i <= 13;
    data_a_i <= 8'hEE;
    
    @(posedge clk_i);
    we_a_i <= 0;
    wait_n_cycles(1);
    
    // Чтение с отключенным портом
    @(posedge clk_i);
    en_a_i   <= 0;  // Порт отключен!
    addr_a_i <= 13;
    wait_n_cycles(2);
    $display("Чтение с отключенным портом A: data=0x%h", data_a_o);
    // Вывод должен сохранить предыдущее значение
    
    @(posedge clk_i);
    en_a_i <= 0;
  endtask

  // Мониторинг изменений
  always @(posedge clk_i) begin
    if (en_a_i && we_a_i)
      $display("[%0t] Запись PORT_A: addr=%0d, data=0x%h", 
               $time, addr_a_i, data_a_i);
    
    if (en_b_i && we_b_i)
      $display("[%0t] Запись PORT_B: addr=%0d, data=0x%h", 
               $time, addr_b_i, data_b_i);
  end

endmodule