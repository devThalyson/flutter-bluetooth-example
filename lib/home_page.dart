import 'dart:async';

import 'package:estudo_bluetooth/shared/functions/functions.dart';
import 'package:estudo_bluetooth/shared/styles/text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  FlutterBluePlus flutterBlue = FlutterBluePlus.instance;

  bool? dispositivoSuportaBluetooth;

  bool? bluetoothEstaAtivado;

  List<ScanResult> dispositivosBluetoothDisponiveis = [];

  List<List<BluetoothCharacteristic>> bluetoothCharacteristics = [];

  List<BluetoothDevice> dispositivosJaConectadosAoAparelho = [];

  bool scanEmAndamento = false;

  StreamSubscription<List<int>>? servicoEscutado;

  bool pesoEstavel = false;

  String peso = '0.0';

  @override
  void initState() {
    _checarSeDispositivoSuportaBluetooth();
    _checarSeBluetoothEstaAtivado();
    _checarDispositivosConectadosAoAparelho();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Testando Bluetooth',
        ),
      ),
      body: Container(
        margin: EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 10,
        ),
        width: double.infinity,
        height: double.infinity,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  text: 'Dispositivo suporta bluetooth? ',
                  style: TextStyles.DEFAULT_STYLE,
                  children: [
                    TextSpan(
                      text: dispositivoSuportaBluetooth == true ? 'Sim' : 'Não',
                      style: TextStyles.STYLE_ONE,
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 10,
              ),
              Row(
                children: [
                  RichText(
                    text: TextSpan(
                      text: 'Seu bluetooth está ativado? ',
                      style: TextStyles.DEFAULT_STYLE,
                      children: [
                        TextSpan(
                          text: bluetoothEstaAtivado != null &&
                                  bluetoothEstaAtivado!
                              ? 'Sim'
                              : 'Não',
                          style: TextStyles.STYLE_ONE,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    splashRadius: 15,
                    onPressed: () async {
                      await _checarSeBluetoothEstaAtivado();

                      if (bluetoothEstaAtivado == true) {
                        await _checarDispositivosConectadosAoAparelho();
                        await _scanearDispositivosDisponiveis();
                      } else {
                        dispositivosJaConectadosAoAparelho.clear();
                        dispositivosBluetoothDisponiveis.clear();

                        setState(() {});
                      }
                    },
                    icon: Icon(
                      Icons.refresh,
                      color: Colors.blue,
                    ),
                  )
                ],
              ),
              SizedBox(
                height: 10,
              ),
              Visibility(
                visible: dispositivoSuportaBluetooth == true &&
                    bluetoothEstaAtivado == true,
                child: Text(
                  'Dispostivos já conectados ao seu aparelho:',
                  style: TextStyles.DEFAULT_STYLE,
                ),
              ),
              Visibility(
                visible: dispositivoSuportaBluetooth == true &&
                    bluetoothEstaAtivado == true,
                child: Visibility(
                  replacement: Text(
                    'Não existem dispositivos bluetooths conectados ao seu aparelho.',
                    style: TextStyles.STYLE_ONE,
                  ),
                  visible: dispositivosJaConectadosAoAparelho.isNotEmpty,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: dispositivosJaConectadosAoAparelho.length,
                    itemBuilder: (_, index) {
                      BluetoothDevice dispostivoConectado =
                          dispositivosJaConectadosAoAparelho[index];
                      return Row(
                        children: [
                          Text(
                            'Nome: ' + dispostivoConectado.name,
                            style: TextStyles.STYLE_ONE,
                          ),
                          IconButton(
                            splashRadius: 15,
                            onPressed: () async {
                              await _desconectarDispositivoBluetooth(
                                dispostivoConectado,
                              );

                              dispositivosJaConectadosAoAparelho.remove(
                                dispositivosJaConectadosAoAparelho[index],
                              );

                              setState(() {});
                            },
                            icon: Icon(
                              Icons.remove_circle,
                              color: Colors.red,
                            ),
                          )
                        ],
                      );
                    },
                  ),
                ),
              ),
              SizedBox(
                height: 10,
              ),
              Visibility(
                visible: bluetoothEstaAtivado != null && bluetoothEstaAtivado!,
                child: _botao(
                  'Escanear dispositivos',
                  _scanearDispositivosDisponiveis,
                ),
              ),
              Visibility(
                replacement: Center(
                  child: CircularProgressIndicator(
                    color: Colors.blue,
                  ),
                ),
                visible: !scanEmAndamento,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: dispositivosBluetoothDisponiveis.length,
                  itemBuilder: (context, index) {
                    final dispositivoDisponivel =
                        dispositivosBluetoothDisponiveis[index].device;

                    return Container(
                      margin: EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 5,
                      ),
                      child: Row(
                        children: [
                          RichText(
                            text: TextSpan(
                              text: 'Dispositivo: ',
                              style: TextStyles.DEFAULT_STYLE,
                              children: [
                                TextSpan(
                                  text: dispositivoDisponivel.name,
                                  style: TextStyles.STYLE_ONE,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            splashRadius: 15,
                            onPressed: () async {
                              await _conectarAoDispositivo(
                                dispositivoDisponivel,
                              );

                              dispositivosBluetoothDisponiveis.remove(
                                dispositivosBluetoothDisponiveis[index],
                              );

                              setState(() {});
                            },
                            icon: Icon(
                              Icons.bluetooth_connected_sharp,
                              color: Colors.blue,
                            ),
                          )
                        ],
                      ),
                    );
                  },
                ),
              ),
              SizedBox(
                height: 10,
              ),
              Visibility(
                visible: dispositivosJaConectadosAoAparelho.isNotEmpty,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        text: 'Peso: ',
                        children: [
                          TextSpan(
                            text: peso,
                            style: TextStyles.STYLE_ONE,
                          ),
                        ],
                        style: TextStyles.DEFAULT_STYLE,
                      ),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Container(
                      alignment: Alignment.center,
                      color: pesoEstavel &&
                              !peso.startsWith(
                                '0',
                              )
                          ? Colors.red
                          : Colors.grey,
                      width: 125,
                      height: 75,
                      child: Text(
                        'PESO ESTÁVEL',
                        style: TextStyles.STYLE_ONE,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _desconectarDispositivoBluetooth(BluetoothDevice device) async {
    await _pararDeEscutarCaracteristicaDePesagem();

    await device.disconnect();

    setState(
      () {
        bluetoothCharacteristics.forEach(
          (characteristcs) {
            characteristcs.removeWhere(
              (element) => element.deviceId == device.id,
            );
          },
        );

        bluetoothCharacteristics.removeWhere((element) => element.isEmpty);
      },
    );

    await _scanearDispositivosDisponiveis();
  }

  _conectarAoDispositivo(BluetoothDevice device) async {
    await device.connect();

    List<BluetoothService> services = await device.discoverServices();

    services.forEach(
      (service) {
        {
          bluetoothCharacteristics.add(
            service.characteristics,
          );
        }
      },
    );

    await _recebendoPesagem();

    await _checarDispositivosConectadosAoAparelho();
  }

  _checarDispositivosConectadosAoAparelho() async {
    try {
      dispositivosJaConectadosAoAparelho = await flutterBlue.connectedDevices;

      dispositivosJaConectadosAoAparelho.forEach(
        (element) async {
          List<BluetoothService> services = await element.discoverServices();

          services.forEach(
            (service) {
              {
                bluetoothCharacteristics.add(
                  service.characteristics,
                );
              }
            },
          );

          await _recebendoPesagem();
        },
      );

      setState(() {});
    } catch (e) {
      print(e);
    }
  }

  _recebendoPesagem() {
    bluetoothCharacteristics.forEach(
      (listCharacteristics) {
        listCharacteristics.forEach(
          (element) async {
            await _escutandoCaracteristicaDePesagem(element);
          },
        );
      },
    );
  }

  _pararDeEscutarCaracteristicaDePesagem() async {
    bluetoothCharacteristics.forEach(
      (listCharacteristics) {
        listCharacteristics.forEach(
          (element) async {
            if (element.uuid.toString() ==
                '00002a9d-0000-1000-8000-00805f9b34fb') {
              await element.setNotifyValue(false);

              await servicoEscutado!.cancel();
            }
          },
        );
      },
    );
  }

  _escutandoCaracteristicaDePesagem(BluetoothCharacteristic element) async {
    if (element.uuid.toString() == '00002a9d-0000-1000-8000-00805f9b34fb') {
      await element.setNotifyValue(true);

      servicoEscutado = element.value.listen(
        (event) async {
          setState(() {
            peso = Functions.calcularPesagem(event);

            if (event.isNotEmpty) {
              pesoEstavel = !(event[10] == 255);
            }
          });
        },
      );

      setState(() {});
    }
  }

  _scanearDispositivosDisponiveis() async {
    dispositivosBluetoothDisponiveis = [];

    try {
      setState(() {
        scanEmAndamento = true;
      });

      // Start scanning
      await flutterBlue.startScan(
        timeout: Duration(
          seconds: 5,
        ),
      );

      // Listen to scan results
      flutterBlue.scanResults.listen(
        (results) {
          // do something with scan results
          for (ScanResult r in results) {
            if (!dispositivosBluetoothDisponiveis.contains(
                  r,
                ) &&
                r.device.name.startsWith('S3 ')) {
              dispositivosBluetoothDisponiveis.add(r);
              setState(() {});
            }
          }
        },
      );

      // Stop scanning
      await flutterBlue.stopScan();

      setState(() {
        scanEmAndamento = false;
      });
    } catch (e) {
      print(e);
    }
  }

  _checarSeBluetoothEstaAtivado() async {
    bluetoothEstaAtivado = await flutterBlue.isOn;

    setState(() {});
  }

  _checarSeDispositivoSuportaBluetooth() async {
    dispositivoSuportaBluetooth = await flutterBlue.isAvailable;

    setState(() {});
  }

  _botao(
    String title,
    Function onTap,
  ) {
    return Container(
      margin: EdgeInsets.symmetric(
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(
          20,
        ),
      ),
      width: 150,
      height: 100,
      child: TextButton(
        onPressed: () => onTap(),
        child: Text(
          title,
          style: TextStyle(
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
