#include "totvs.ch"
#include "restful.ch"

/*/{Protheus.doc} CHANGENSU
    (Correção do NSU que vem da integração com E-commerce)
    @type    Classe Rest
    @author  José Novaes - TSM
    @since   05/12/2021
    @version 1.0
    @param   param_name, param_type, param_descr
    @return  return_var, return_type, return_description
    @example
    (examples)
    @see (links_or_references)
/*/
WSRESTFUL changensu DESCRIPTION "Acerto do NSU VTEX x SIGALOJA"

    WSMETHOD PUT DESCRIPTION "Modificar o NSU errado" WSSYNTAX "NSUVTEX" PATH "NSUVTEX"

END WSRESTFUL


WSMETHOD PUT WSSERVICE changensu
    Local lRet      := .T.         // Recebe o Retorno 
    Local cBody     := ""          // Recebe o conteudo do Rest
    Local oJson     := NIL         // Recebe o JSON de Entrada
    Local oJsonRet  := NIL         // Recebe o JSON de Saida
    Local cPedEcom  := ""
    Local cNSU      := ""
    Local cQryUpd   := ""
    Local nErro     := 0

    // Pega o conteudo JSON da transação Rest
    cBody := ::GetContent()
    ::SetContentType("application/json")
    oJson := JsonObject():new()
    oJson:fromJson(cBody)
  
    cPedEcom  := oJson:GetJSonObject('OrderId')
    cNSU      := oJson:GetJSonObject('nsu')

    Begin Transaction

    cQryUpd := " UPDATE " + RetSqlName("SL1") + " "
    cQryUpd += "     SET L1_NSUTEF = '" + cNSU + "' "
    cQryUpd += " WHERE "
    cQryUpd += "     D_E_L_E_T_ = ' ' "
    cQryUpd += "     AND L1_FILIAL = '" + FWxFilial("SL1") + "' "
    cQryUpd += "     AND L1_ECPEDEC = '" + cPedEcom + "' "
    nErro := TcSqlExec(cQryUpd)
     
    If nErro != 0
        ConOut("CHANGENSU - "+cPedEcom+" Erro na execução da query SL1: "+TcSqlError())
        DisarmTransaction()
    Else
        cQryUpd := " UPDATE " + RetSqlName("SE1") + " "
        cQryUpd += "     SET E1_NSUTEF = '" + cNSU + "' "
        cQryUpd += " WHERE "
        cQryUpd += "     D_E_L_E_T_ = ' ' "
        cQryUpd += "     AND E1_FILIAL = '" + FWxFilial("SE1") + "' "
        cQryUpd += "     AND E1_NRDOC = '" + cPedEcom + "' "
        nErro := TcSqlExec(cQryUpd)
        
        If nErro != 0
            ConOut("CHANGENSU - "+cPedEcom+" Erro na execução da query SE1: "+TcSqlError())
            DisarmTransaction()
        EndIf
        
    EndIf

    End Transaction
  
    // Monta Objeto JSON de retorno
    oJsonRet := NIL
    oJsonRet := JsonObject():new()
    oJsonRet['retorno'] := IIF(nErro != 0,"erro","ok")
  
    // Devolve o retorno para o Rest
    ::SetResponse(oJsonRet:toJSON())
        
    FreeObj(oJsonRet)
    FreeObj(oJson)
Return lRet
