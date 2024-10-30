trait TicketRoyalty {
    royalty_destination: Address;
    numerator: Int;
    denominator: Int;

    receive(msg: GetRoyaltyRequest) {
        send(SendParameters{
            to: sender(),
            value: 0,
            mode: SendRemainingValue,
            body: NftReportRoyaltyParams{
                query_id: msg.query_id,
                numerator: self.numerator,
                denominator: self.denominator,
                destination: self.royalty_destination
            }.toCell()
        });
    }

    get fun royalty_params(): NftRoyaltyParams {
        return NftRoyaltyParams{
            numerator: self.numerator,
            denominator: self.denominator,
            royalty_destination: self.royalty_destination
        };
    }
}